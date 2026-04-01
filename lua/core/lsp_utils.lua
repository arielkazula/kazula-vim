-- lua/core/lsp_utils.lua --------------------------------------------------
-- Advanced LSP utilities to solve the "Header Reference" problem.

local M = {}

--- Smart Contextual References
-- Finds files via Ripgrep, "injects" them into Clangd's active memory 
-- via didOpen notifications, and then runs semantic references.
function M.smart_references()
    local word = vim.fn.expand("<cword>")
    if word == "" then 
        vim.notify("SmartRef: No word under cursor.", vim.log.levels.WARN)
        return 
    end

    local bufnr = vim.api.nvim_get_current_buf()
    local clients = vim.lsp.get_clients({ bufnr = bufnr, name = "clangd" })
    local clangd = clients[1]

    if not clangd then
        vim.notify("SmartRef: Clangd not attached to this buffer.", vim.log.levels.ERROR)
        return
    end

    -- 1. Use Ripgrep to find potential files
    vim.notify("SmartRef: Searching for '" .. word .. "' via ripgrep...", vim.log.levels.INFO)
    
    local rg_cmd = string.format("rg -l --fixed-strings --word-regexp '%s'", word)
    local handle = io.popen(rg_cmd)
    if not handle then 
        vim.notify("SmartRef: Failed to run ripgrep.", vim.log.levels.ERROR)
        return 
    end
    
    local files = handle:read("*a")
    handle:close()

    local file_list = {}
    for file in files:gmatch("[^\r\n]+") do
        table.insert(file_list, file)
    end

    if #file_list == 0 then
        vim.notify("SmartRef: No files found via grep. Falling back to standard LSP...", vim.log.levels.WARN)
        require('fzf-lua').lsp_references()
        return
    end

    -- 2. Inject context into Clangd
    local inject_count = 0
    local max_inject = 15 -- Limit to prevent server lag
    
    for _, file_path in ipairs(file_list) do
        local abs_path = vim.fn.fnamemodify(file_path, ":p")
        local uri = vim.uri_from_fname(abs_path)
        
        -- Check if Clangd already knows about this file
        -- We use a hacky way to check "active" documents if possible, 
        -- but didOpen is idempotent so we can just send it.
        local ok, lines = pcall(vim.fn.readfile, abs_path)
        if ok and lines then
            local content = table.concat(lines, "\n")
            local ft = vim.filetype.match({ filename = abs_path }) or "cpp"
            
            -- didOpen MUST have version and text
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
        
        if inject_count >= max_inject then break end
    end

    vim.notify(string.format("SmartRef: Injected %d files into Clangd. Waiting for parse...", inject_count), vim.log.levels.INFO)

    -- 3. Run LSP references after a delay
    vim.defer_fn(function()
        vim.schedule(function()
            vim.notify("SmartRef: Querying Clangd for semantic references...", vim.log.levels.INFO)
            require('fzf-lua').lsp_references({
                include_declaration = true,
                jump1 = true,
                winopts = { title = " Smart References: " .. word .. " " }
            })
        end)
    end, 1200) -- Increased delay for large files
end

return M
