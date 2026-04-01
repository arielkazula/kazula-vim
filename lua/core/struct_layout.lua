-- lua/core/struct_layout.lua ----------------------------------------------
-- A specialized tool to visualize C++ struct/class memory layout.
-- This queries clangd's symbolInfo for every member to build a layout table.

local M = {}

local function create_floating_window(lines, title)
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].modifiable = false
    vim.bo[buf].filetype = "markdown"

    local width = 60
    local height = math.min(#lines, 20)
    
    local win = vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        width = width,
        height = height,
        row = (vim.o.lines - height) / 2,
        col = (vim.o.columns - width) / 2,
        style = "minimal",
        border = "rounded",
        title = " " .. title .. " ",
        title_pos = "center",
    })
    
    -- Close on 'q' or Esc
    vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = buf, silent = true })
    vim.keymap.set("n", "<Esc>", "<cmd>close<cr>", { buffer = buf, silent = true })
end

function M.show_layout()
    local params = vim.lsp.util.make_position_params(0, "utf-16")
    
    -- 1. Get the symbol at cursor to see if it's a struct/class or a member
    vim.lsp.buf_request(0, "textDocument/documentSymbol", params, function(err, symbols)
        if err or not symbols then 
            vim.notify("Could not fetch document symbols", vim.log.levels.WARN)
            return 
        end

        local cursor = vim.api.nvim_win_get_cursor(0)
        local line, col = cursor[1] - 1, cursor[2]

        -- Find the struct/class containing the cursor
        local target_node = nil
        local function find_container(nodes)
            for _, node in ipairs(nodes) do
                local r = node.range or node.selectionRange
                if r.start.line <= line and r["end"].line >= line then
                    -- If it's a Class (5) or Struct (23)
                    if node.kind == 5 or node.kind == 23 then
                        target_node = node
                    end
                    if node.children then find_container(node.children) end
                end
            end
        end
        find_container(symbols)

        if not target_node or not target_node.children then
            vim.notify("Cursor is not inside a struct or class", vim.log.levels.INFO)
            return
        end

        local fields = {}
        for _, child in ipairs(target_node.children) do
            -- Field (8), EnumMember (22), or potentially others
            if child.kind == 8 or child.kind == 22 then
                table.insert(fields, child)
            end
        end

        if #fields == 0 then
            vim.notify("No fields found in " .. target_node.name, vim.log.levels.INFO)
            return
        end

        -- 2. Query symbolInfo for the container and each field
        local layout_data = {}
        local remaining = #fields + 1
        
        local timer = vim.loop.new_timer()
        local function finalize()
            if remaining == -1 then return end -- Already finalized
            remaining = remaining - 1
            if remaining > 0 then return end
            
            remaining = -1 -- Mark as done
            if timer then timer:stop(); timer:close() end

            if #layout_data == 0 then
                vim.notify("Could not retrieve layout information from clangd", vim.log.levels.WARN)
                return
            end
            
            -- Sort fields by offset
            table.sort(layout_data, function(a, b) 
                return (a.offset or 0) < (b.offset or 0) 
            end)

            -- Format the output
            local lines = {
                string.format("# Layout: %s", target_node.name),
                "",
                "| Offset | Size | Member | Type |",
                "|--------|------|--------|------|",
            }

            local last_offset = 0
            local last_size = 0
            local total_size = 0

            for _, item in ipairs(layout_data) do
                if item.is_container then
                    total_size = item.size
                else
                    -- Detect padding
                    if item.offset > (last_offset + last_size) then
                        local pad_size = item.offset - (last_offset + last_size)
                        table.insert(lines, string.format("| %6d | %4d | *padding* | |", last_offset + last_size, pad_size))
                    end
                    
                    table.insert(lines, string.format("| %6d | %4d | %-15s | %s |", 
                        item.offset, item.size, item.name, item.detail or ""))
                    
                    last_offset = item.offset
                    last_size = item.size
                end
            end

            -- Check for trailing padding
            if total_size > (last_offset + last_size) then
                local pad_size = total_size - (last_offset + last_size)
                table.insert(lines, string.format("| %6d | %4d | *padding* | |", last_offset + last_size, pad_size))
            end

            table.insert(lines, "")
            table.insert(lines, string.format("**Total Size:** %d bytes (Align: %d)", total_size, layout_data.alignment or 0))
            
            create_floating_window(lines, target_node.name)
        end

        -- Force finalize after 2 seconds if some requests are stuck
        timer:start(2000, 0, vim.schedule_wrap(function()
            if remaining > 0 then
                remaining = 1
                finalize()
            end
        end))

        -- Request for container
        local container_params = {
            textDocument = params.textDocument,
            position = target_node.selectionRange.start
        }
        vim.lsp.buf_request(0, "textDocument/symbolInfo", container_params, function(_, res)
            if res and res[1] and res[1].layout then
                layout_data.alignment = res[1].layout.alignment
                table.insert(layout_data, { is_container = true, size = res[1].layout.size })
            end
            finalize()
        end)

        -- Request for each field
        for _, field in ipairs(fields) do
            local field_params = {
                textDocument = params.textDocument,
                position = field.selectionRange.start
            }
            vim.lsp.buf_request(0, "textDocument/symbolInfo", field_params, function(_, res)
                if res and res[1] and res[1].layout then
                    table.insert(layout_data, {
                        name = field.name,
                        detail = field.detail,
                        offset = res[1].layout.offset,
                        size = res[1].layout.size
                    })
                end
                finalize()
            end)
        end
    end)
end

return M
