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
        vim.notify("SmartRef: No files found via grep. Using standard LSP...", vim.log.levels.WARN)
        require('fzf-lua').lsp_references()
        return
    end

    -- 2. Inject context into Clangd
    local inject_count = 0
    local max_inject = 15 
    
    for _, file_path in ipairs(file_list) do
        local abs_path = vim.fn.fnamemodify(file_path, ":p")
        local uri = vim.uri_from_fname(abs_path)
        
        local ok, lines = pcall(vim.fn.readfile, abs_path)
        if ok and lines then
            local content = table.concat(lines, "\n")
            local ft = vim.filetype.match({ filename = abs_path }) or "cpp"
            
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

    vim.notify(string.format("SmartRef: Injected %d files. Requesting references...", inject_count), vim.log.levels.INFO)

    -- 3. Run LSP references
    -- We'll use a slightly longer delay and try a direct LSP request first to verify data
    vim.defer_fn(function()
        vim.schedule(function()
            local params = vim.lsp.util.make_position_params(0, "utf-16")
            params.context = { includeDeclaration = true }
            
            clangd.request("textDocument/references", params, function(err, result)
                if err then
                    vim.notify("SmartRef LSP Error: " .. err.message, vim.log.levels.ERROR)
                    return
                end
                
                if not result or #result == 0 then
                    vim.notify("SmartRef: Clangd found 0 semantic references. Is indexing complete?", vim.log.levels.WARN)
                    return
                end
                
                vim.notify(string.format("SmartRef: Found %d references. Opening picker...", #result), vim.log.levels.INFO)
                
                -- Now that we HAVE results, use fzf-lua to show them
                require('fzf-lua').lsp_references({
                    include_declaration = true,
                    jump1 = true,
                    winopts = { title = " Smart References: " .. word .. " " }
                })
            end, bufnr)
        end)
    end, 1500) 
end

return M
