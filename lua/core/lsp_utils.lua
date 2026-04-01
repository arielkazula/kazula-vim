-- lua/core/lsp_utils.lua --------------------------------------------------
-- Advanced LSP utilities to solve the "Header Reference" problem.

local M = {}

--- Smart Contextual References
-- This function finds all files containing the word under cursor via Ripgrep,
-- forces clangd to "load" them as active context, and then asks for references.
-- This ensures clangd sees the semantic links even if background indexing is slow.
function M.smart_references()
    local word = vim.fn.expand("<cword>")
    if word == "" then return end

    vim.notify("SmartRef: Injecting context for '" .. word .. "'...", vim.log.levels.INFO)

    -- 1. Use Ripgrep to find files that mention this word (fast)
    -- We only care about file paths (-l)
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
        vim.notify("SmartRef: No files found containing word.", vim.log.levels.WARN)
        return
    end

    -- 2. "Warm up" Clangd by simulating opening these files
    -- We don't actually open buffers (too slow), we just notify the LSP
    -- that these files are now "active" in our workspace context.
    local count = 0
    for _, file_path in ipairs(file_list) do
        local abs_path = vim.fn.fnamemodify(file_path, ":p")
        local uri = vim.uri_from_fname(abs_path)
        
        -- We send a dummy request or just ensure clangd is aware of the file
        -- Triggering a documentSymbol request is a lightweight way to force 
        -- clangd to parse the file and link its symbols.
        vim.lsp.buf_request(0, "textDocument/documentSymbol", {
            textDocument = { uri = uri }
        }, function() end)
        
        count = count + 1
        if count > 50 then break end -- Limit to 50 files to prevent LSP overload
    end

    -- 3. Now run the actual LSP references request
    -- Since we "poked" clangd about the relevant files, it's much more
    -- likely to have the semantic context ready.
    vim.defer_fn(function()
        require('fzf-lua').lsp_references({
            include_declaration = true,
            jump1 = true,
            winopts = { title = " Smart LSP References: " .. word .. " " }
        })
    end, 500) -- Small delay to allow LSP to process the "pokes"
end

return M
