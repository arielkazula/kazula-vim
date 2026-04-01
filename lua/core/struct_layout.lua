-- lua/core/struct_layout.lua ----------------------------------------------
-- A specialized tool to visualize C++ struct/class memory layout.
-- This queries clangd's symbolInfo for member layouts with indexing awareness.

local M = {}

local function create_floating_window(lines, title)
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].modifiable = false
    vim.bo[buf].filetype = "markdown"

    local width = 95
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
    local bufnr = vim.api.nvim_get_current_buf()
    local clients = vim.lsp.get_clients({ bufnr = bufnr, name = "clangd" })
    local clangd = clients[1]

    if not clangd then
        vim.notify("StructLayout: Clangd is not attached", vim.log.levels.ERROR)
        return
    end

    local params = vim.lsp.util.make_position_params(0, "utf-16")
    
    -- Request document symbols
    clangd.request("textDocument/documentSymbol", params, function(err, symbols)
        if err or not symbols then 
            vim.notify("StructLayout: LSP busy or indexing. Try again in a moment.", vim.log.levels.WARN)
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
                    if node.kind == 5 or node.kind == 23 then target_node = node end
                    if node.children then find_container(node.children) end
                end
            end
        end
        find_container(symbols)

        if not target_node then
            vim.notify("StructLayout: Cursor not on a struct/class", vim.log.levels.INFO)
            return
        end

        -- Flatten members
        local candidates = {}
        local function collect(nodes)
            for _, node in ipairs(nodes) do
                if node.kind == 8 or node.kind == 22 or node.kind == 7 or node.kind == 13 then
                    table.insert(candidates, node)
                end
                if node.children then collect(node.children) end
            end
        end
        collect(target_node.children or {})

        if #candidates == 0 then
            vim.notify("StructLayout: No data members in " .. target_node.name, vim.log.levels.INFO)
            return
        end

        -- Notify user about start
        local progress_notif = vim.notify(
            string.format("StructLayout: Analyzing %d members in %s...", #candidates, target_node.name),
            vim.log.levels.INFO,
            { title = "LSP Analysis", timeout = 10000 }
        )

        -- 2. Query each candidate
        local layout_data = {}
        local remaining = #candidates + 1
        local alignment, total_size = 0, 0
        local success_count = 0
        
        local timer = vim.loop.new_timer()
        local function finalize()
            if remaining == -1 then return end
            remaining = remaining - 1
            if remaining > 0 then return end
            
            remaining = -1
            if timer then timer:stop(); timer:close() end

            if success_count == 0 then
                vim.notify(
                    "StructLayout: Indexing incomplete. Clangd hasn't calculated memory layout for this file yet.",
                    vim.log.levels.WARN,
                    { title = "LSP Indexing" }
                )
                return
            end
            
            table.sort(layout_data, function(a, b) return (a.offset or 0) < (b.offset or 0) end)

            -- Build result lines
            local lines = {
                string.format("# Layout: %s", target_node.name),
                "",
                "| Offset | Size | Member | Type |",
                "|--------|------|--------|------|",
            }

            local last_offset, last_size = 0, 0
            for _, item in ipairs(layout_data) do
                if item.offset > (last_offset + last_size) then
                    table.insert(lines, string.format("| %6d | %4d | *padding* | |", last_offset + last_size, item.offset - (last_offset + last_size)))
                end
                table.insert(lines, string.format("| %6d | %4d | %-35s | %s |", item.offset, item.size, item.name, item.detail or ""))
                last_offset, last_size = item.offset, item.size
            end

            if total_size > (last_offset + last_size) then
                table.insert(lines, string.format("| %6d | %4d | *padding* | |", last_offset + last_size, total_size - (last_offset + last_size)))
            end

            table.insert(lines, "")
            table.insert(lines, string.format("**Total Size:** %d bytes | **Alignment:** %d bytes", total_size, alignment))
            
            create_floating_window(lines, target_node.name)
        end

        -- 20s timeout for huge classes
        timer:start(20000, 0, vim.schedule_wrap(function()
            if remaining > 0 then
                remaining = 1
                finalize()
            end
        end))

        local function get_layout(node, callback)
            local lsp_params = { textDocument = params.textDocument, position = node.selectionRange.start }
            -- Try both method names quietly
            clangd.request("textDocument/symbolInfo", lsp_params, function(_, res)
                local l = res and res[1] and res[1].layout or (res and res.layout)
                if l then 
                    success_count = success_count + 1
                    return callback(l) 
                end
                
                clangd.request("clangd/symbolInfo", lsp_params, function(_, res2)
                    local l2 = res2 and res2.layout or (res2 and res2[1] and res2[1].layout)
                    if l2 then success_count = success_count + 1 end
                    callback(l2)
                end)
            end, bufnr)
        end

        -- Get container info
        get_layout(target_node, function(l)
            if l then alignment, total_size = l.alignment or 0, l.size or 0 end
            finalize()
        end)

        -- Get member info
        for _, cand in ipairs(candidates) do
            get_layout(cand, function(l)
                if l and l.offset ~= nil then
                    table.insert(layout_data, {
                        name = cand.name,
                        detail = cand.detail or "",
                        offset = l.offset,
                        size = l.size or 0
                    })
                end
                finalize()
            end)
        end
    end, bufnr)
end

return M
