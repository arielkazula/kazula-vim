-- lua/core/struct_layout.lua ----------------------------------------------
-- A specialized tool to visualize C++ struct/class memory layout.
-- This queries clangd's symbolInfo for member layouts.

local M = {}

local function create_floating_window(lines, title)
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].modifiable = false
    vim.bo[buf].filetype = "markdown"

    local width = 95
    local height = math.min(#lines, 45)
    
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
    
    -- Try to "wake up" clangd by requesting document symbols first
    vim.lsp.buf_request(0, "textDocument/documentSymbol", params, function(err, symbols)
        if err or not symbols then 
            vim.notify("StructLayout: Could not fetch document symbols. Is the LSP ready?", vim.log.levels.ERROR)
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
                -- Field, EnumMember, Property, Variable
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

        vim.notify(string.format("StructLayout: Probing %d members in %s...", #candidates, target_node.name), vim.log.levels.INFO)

        -- 2. Query each candidate
        local layout_data = {}
        local remaining = #candidates + 1
        local alignment = 0
        local total_size = 0
        local error_log = {}
        
        local timer = vim.loop.new_timer()
        local function finalize()
            if remaining == -1 then return end -- Already finalized
            remaining = remaining - 1
            if remaining > 0 then return end
            
            remaining = -1 -- Mark as done
            if timer then timer:stop(); timer:close() end

            if #layout_data == 0 then
                vim.notify("StructLayout: Clangd returned no layout data. Check :messages for LSP errors.", vim.log.levels.ERROR)
                print("StructLayout Errors:")
                for _, msg in ipairs(error_log) do print("  " .. msg) end
                return
            end
            
            table.sort(layout_data, function(a, b) return (a.offset or 0) < (b.offset or 0) end)

            local lines = {
                string.format("# Layout: %s", target_node.name),
                "",
                "| Offset | Size | Member | Type |",
                "|--------|------|--------|------|",
            }

            local last_offset = 0
            local last_size = 0

            for _, item in ipairs(layout_data) do
                if item.offset > (last_offset + last_size) then
                    local pad_size = item.offset - (last_offset + last_size)
                    table.insert(lines, string.format("| %6d | %4d | *padding* | |", last_offset + last_size, pad_size))
                end
                
                table.insert(lines, string.format("| %6d | %4d | %-35s | %s |", 
                    item.offset, item.size, item.name, item.detail or ""))
                
                last_offset = item.offset
                last_size = item.size
            end

            if total_size > (last_offset + last_size) then
                local pad_size = total_size - (last_offset + last_size)
                table.insert(lines, string.format("| %6d | %4d | *padding* | |", last_offset + last_size, pad_size))
            end

            table.insert(lines, "")
            table.insert(lines, string.format("**Total Size:** %d bytes | **Alignment:** %d bytes", total_size, alignment))
            
            create_floating_window(lines, target_node.name)
        end

        timer:start(12000, 0, vim.schedule_wrap(function()
            if remaining > 0 then
                table.insert(error_log, "TIMEOUT: Clangd is taking too long (Indexing?)")
                remaining = 1
                finalize()
            end
        end))

        -- The core layout fetcher
        local function get_layout(node, callback)
            local pos = node.selectionRange.start
            local lsp_params = { textDocument = params.textDocument, position = pos }
            
            -- Use the clangd/ prefix which is the correct one for clangd-specific methods
            vim.lsp.buf_request(0, "clangd/symbolInfo", lsp_params, function(err, res)
                if not err and res and res.layout then
                    -- Note: clangd/symbolInfo usually returns a single object, not a list
                    callback(res.layout)
                elseif not err and res and res[1] and res[1].layout then
                    -- Some versions return a list
                    callback(res[1].layout)
                else
                    -- If clangd/ fails, try textDocument/symbolInfo just in case
                    vim.lsp.buf_request(0, "textDocument/symbolInfo", lsp_params, function(err2, res2)
                        if not err2 and res2 and res2[1] and res2[1].layout then
                            callback(res2[1].layout)
                        else
                            local msg = string.format("Failed '%s': %s", node.name, err and err.message or "No layout field")
                            table.insert(error_log, msg)
                            callback(nil)
                        end
                    end)
                end
            end)
        end

        -- Request for container
        get_layout(target_node, function(layout)
            if layout then
                alignment = layout.alignment or 0
                total_size = layout.size or 0
            end
            finalize()
        end)

        -- Request for each candidate
        for _, cand in ipairs(candidates) do
            get_layout(cand, function(layout)
                if layout and layout.offset ~= nil then
                    table.insert(layout_data, {
                        name = cand.name,
                        detail = cand.detail or "",
                        offset = layout.offset,
                        size = layout.size or 0
                    })
                end
                finalize()
            end)
        end
    end)
end

return M
