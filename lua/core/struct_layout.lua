-- lua/core/struct_layout.lua ----------------------------------------------
-- A specialized tool to visualize C++ struct/class memory layout.
-- This queries clangd's symbolInfo for every member to build a layout table.

local M = {}

local function create_floating_window(lines, title)
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].modifiable = false
    vim.bo[buf].filetype = "markdown"

    local width = 80
    local height = math.min(#lines, 30)
    
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
                    -- Recurse if children exist (to find nested structs)
                    if node.children then find_container(node.children) end
                end
            end
        end
        find_container(symbols)

        if not target_node then
            vim.notify("Cursor is not inside a struct or class", vim.log.levels.INFO)
            return
        end

        -- Flatten children and filter for fields/members
        local candidates = {}
        local function collect_candidates(node)
            if not node.children then return end
            for _, child in ipairs(node.children) do
                -- Field (8), EnumMember (22), Property (7), Variable (13)
                -- We include more kinds because some members might be reported differently
                if child.kind == 8 or child.kind == 22 or child.kind == 7 or child.kind == 13 then
                    table.insert(candidates, child)
                end
                -- We don't recurse here because we only want immediate members of the target class
            end
        end
        collect_candidates(target_node)

        if #candidates == 0 then
            vim.notify("No members found in " .. target_node.name, vim.log.levels.INFO)
            return
        end

        -- 2. Query symbolInfo for the container and each candidate
        local layout_data = {}
        local remaining = #candidates + 1
        local alignment = 0
        local total_size = 0
        
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

            for _, item in ipairs(layout_data) do
                -- Detect padding
                if item.offset > (last_offset + last_size) then
                    local pad_size = item.offset - (last_offset + last_size)
                    table.insert(lines, string.format("| %6d | %4d | *padding* | |", last_offset + last_size, pad_size))
                end
                
                table.insert(lines, string.format("| %6d | %4d | %-20s | %s |", 
                    item.offset, item.size, item.name, item.detail or ""))
                
                last_offset = item.offset
                last_size = item.size
            end

            -- Check for trailing padding
            if total_size > (last_offset + last_size) then
                local pad_size = total_size - (last_offset + last_size)
                table.insert(lines, string.format("| %6d | %4d | *padding* | |", last_offset + last_size, pad_size))
            end

            table.insert(lines, "")
            table.insert(lines, string.format("**Total Size:** %d bytes | **Alignment:** %d bytes", total_size, alignment))
            
            create_floating_window(lines, target_node.name)
        end

        -- Force finalize after 3 seconds for large classes
        timer:start(3000, 0, vim.schedule_wrap(function()
            if remaining > 0 then
                remaining = 1
                finalize()
            end
        end))

        -- Request for container to get total size and alignment
        local container_params = {
            textDocument = params.textDocument,
            position = target_node.selectionRange.start
        }
        vim.lsp.buf_request(0, "textDocument/symbolInfo", container_params, function(_, res)
            if res and res[1] and res[1].layout then
                alignment = res[1].layout.alignment or 0
                total_size = res[1].layout.size or 0
            end
            finalize()
        end)

        -- Request for each candidate
        for _, cand in ipairs(candidates) do
            local cand_params = {
                textDocument = params.textDocument,
                position = cand.selectionRange.start
            }
            vim.lsp.buf_request(0, "textDocument/symbolInfo", cand_params, function(_, res)
                -- Only include if it has a valid layout (excludes static members which have no offset/size in record)
                if res and res[1] and res[1].layout and res[1].layout.offset ~= nil then
                    table.insert(layout_data, {
                        name = cand.name,
                        detail = cand.detail or "",
                        offset = res[1].layout.offset,
                        size = res[1].layout.size or 0
                    })
                end
                finalize()
            end)
        end
    end)
end

return M
