-- lua/core/lsp_utils.lua --------------------------------------------------
-- Advanced LSP utilities to solve the "Header Reference" problem.

local M = {}

--- Smart Contextual References
-- Finds files via Ripgrep, "injects" them into Clangd's active memory 
-- via didOpen notifications, and then runs semantic references.
function M.smart_references()
    local word = vim.fn.expand("<cword>")
    if word == "" then return end

    local bufnr = vim.api.nvim_get_current_buf()
    local clients = vim.lsp.get_clients({ bufnr = bufnr, name = "clangd" })
    local clangd = clients[1]

    if not clangd then
        vim.notify("SmartRef: Clangd not attached.", vim.log.levels.ERROR)
        return
    end

    -- 1. Use Ripgrep to find potential files
    local cmd = string.format("rg -l --fixed-strings --word-regexp '%s'", word)
    local handle = io.popen(cmd)
    if not handle then return end
    local files = handle:read("*a")
    handle:close()

    local file_list = {}
    for file in files:gmatch("[^\r\n]+") do
        table.insert(file_list, file)
    end

    if #file_list == 0 then
        vim.notify("SmartRef: No files found via grep.", vim.log.levels.WARN)
        return
    end

    -- 2. Inject context into Clangd
    -- We tell Clangd we "opened" these files so it parses them immediately.
    local inject_count = 0
    local max_inject = 20 -- Limit to 20 files to prevent RPC flood
    
    for _, file_path in ipairs(file_list) do
        local abs_path = vim.fn.fnamemodify(file_path, ":p")
        
        -- Only inject if not already managed by LSP
        local uri = vim.uri_from_fname(abs_path)
        if not vim.lsp.get_buffers_by_client_id(clangd.id)[uri] then
            -- Read file content (synchronous but usually fast for source files)
            local ok, lines = pcall(vim.fn.readfile, abs_path)
            if ok and lines then
                local content = table.concat(lines, "\n")
                local ft = vim.filetype.match({ filename = abs_path }) or "cpp"
                
                -- Send didOpen notification (no response expected)
                clangd.notify("textDocument/didOpen", {
                    textDocument = {
                        uri = uri,
                        languageId = ft,
                        version = 1,
                        text = content
                    }
                })
                inject_count = inject_count + 1
            end
        end
        
        if inject_count >= max_inject then break end
    end

    vim.notify(string.format("SmartRef: Injected %d files into Clangd context...", inject_count), vim.log.levels.INFO)

    -- 3. Run LSP references after a short delay to allow parsing
    vim.defer_fn(function()
        require('fzf-lua').lsp_references({
            include_declaration = true,
            jump1 = true,
            winopts = { title = " Smart Contextual References: " .. word .. " " }
        })
    end, 800) 
end

return M
