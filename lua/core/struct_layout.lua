-- lua/core/struct_layout.lua ----------------------------------------------
-- A specialized tool to visualize C++ struct/class memory layout.
-- This queries clangd's symbolInfo for every member to build a layout table.

local M = {}

local function create_floating_window(lines, title)
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].modifiable = false
    vim.bo[buf].filetype = "markdown"

    local width = 90
    local height = math.min(#lines, 40)
    
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
    
    -- 1. Get the symbol at cursor
    vim.lsp.buf_request(0, "textDocument/documentSymbol", params, function(err, symbols)
        if err or not symbols then 
            vim.notify("StructLayout: Could not fetch document symbols", vim.log.levels.ERROR)
            return 
        end

        local cursor = vim.api.nvim_win_get_cursor(0)
        local line = cursor[1] - 1

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

        if not target_node then
            vim.notify("StructLayout: Cursor is not inside a struct or class", vim.log.levels.INFO)
            return
        end

        -- Flatten children recursively
        local candidates = {}
        local function collect_candidates(nodes)
            for _, node in ipairs(nodes) do
                if node.kind == 8 or node.kind == 22 or node.kind == 7 or node.kind == 13 then
                    table.insert(candidates, node)
                end
                if node.children then collect_candidates(node.children) end
            end
        end
        collect_candidates(target_node.children or {})

        if #candidates == 0 then
            vim.notify("StructLayout: No data members found in " .. target_node.name, vim.log.levels.INFO)
            return
        end

        vim.notify(string.format("StructLayout: Analyzing %d members in %s...", #candidates, target_node.name), vim.log.levels.INFO)

        -- 2. Query symbolInfo for the container and each candidate
        local layout_data = {}
        local remaining = #candidates + 1
        local alignment = 0
        local total_size = 0
        local error_list = {}
        
        local timer = vim.loop.new_timer()
        local function finalize()
            if remaining == -1 then return end -- Already finalized
            remaining = remaining - 1
            if remaining > 0 then return end
            
            remaining = -1 -- Mark as done
            if timer then timer:stop(); timer:close() end

            if #layout_data == 0 then
                local debug_msg = "Clangd returned NO layout info. Last error: " .. (error_list[1] or "Unknown")
                vim.notify("StructLayout: " .. debug_msg, vim.log.levels.ERROR)
                print("StructLayout Debug Info:")
                for i, msg in ipairs(error_list) do print(string.format("  [%d] %s", i, msg)) end
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
                
                table.insert(lines, string.format("| %6d | %4d | %-30s | %s |", 
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
            if #error_list > 0 then
                table.insert(lines, string.format("\n*Note: %d members skipped. See :messages for debug details.*", #error_list))
            end
            
            create_floating_window(lines, target_node.name)
        end

        -- Increased timeout for deep analysis
        timer:start(10000, 0, vim.schedule_wrap(function()
            if remaining > 0 then
                table.insert(error_list, "Timeout reached before all members were analyzed.")
                remaining = 1
                finalize()
            end
        end))

        -- Helper to get layout for a symbol with deep logging
        local function get_layout(node, is_container, callback)
            local pos = node.selectionRange.start
            local symbol_params = {
                textDocument = params.textDocument,
                position = pos
            }
            
            vim.lsp.buf_request(0, "textDocument/symbolInfo", symbol_params, function(err, res)
                if err then
                    table.insert(error_list, string.format("LSP error for '%s': %s", node.name, vim.inspect(err)))
                end

                if res and res[1] and res[1].layout then
                    callback(res[1].layout)
                else
                    -- Fallback: If symbolInfo fails at selectionRange, try the start of the full range
                    symbol_params.position = node.range.start
                    vim.lsp.buf_request(0, "textDocument/symbolInfo", symbol_params, function(_, res2)
                        if res2 and res2[1] and res2[1].layout then
                            callback(res2[1].layout)
                        else
                            local reason = "No 'layout' field in clangd/symbolInfo response"
                            if res2 and res2[1] then reason = "Found symbol but layout was missing" end
                            table.insert(error_list, string.format("Failed '%s' at %d:%d - %s", node.name, pos.line, pos.character, reason))
                            callback(nil)
                        end
                    end)
                end
            end)
        end

        -- Request for container
        get_layout(target_node, true, function(layout)
            if layout then
                alignment = layout.alignment or 0
                total_size = layout.size or 0
            end
            finalize()
        end)

        -- Request for each candidate
        for _, cand in ipairs(candidates) do
            get_layout(cand, false, function(layout)
                if layout and layout.offset ~= nil then
                    table.insert(layout_data, {
                        name = cand.name,
                        detail = cand.detail or "",
                        offset = layout.offset,
                        size = layout.size or 0
                    })
                else
                    -- Already logged in get_layout
                end
                finalize()
            end)
        end
    end)
end

return M
