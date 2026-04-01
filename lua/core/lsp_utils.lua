-- lua/core/lsp_utils.lua --------------------------------------------------
-- Advanced LSP utilities to solve the "Header Reference" problem.

local M = {}

--- Format LSP location for FZF-Lua
local function format_lsp_loc(loc)
    local path = vim.uri_to_fname(loc.uri)
    local line = loc.range.start.line + 1
    local col = loc.range.start.character + 1
    local relative_path = vim.fn.fnamemodify(path, ":.")
    
    -- Read the line content for the preview
    local lines = vim.fn.readfile(path)
    local text = lines[line] or ""
    
    -- FZF-Lua format: file:line:col:text
    return string.format("%s:%d:%d:%s", relative_path, line, col, text:gsub("^%s+", ""))
end

--- Smart Contextual References
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

    vim.notify("SmartRef: Grepping and Injecting context...", vim.log.levels.INFO)
    
    local rg_cmd = string.format("rg -l --fixed-strings --word-regexp '%s'", word)
    local handle = io.popen(rg_cmd)
    if not handle then return end
    local files = handle:read("*a")
    handle:close()

    local file_list = {}
    for file in files:gmatch("[^\r\n]+") do table.insert(file_list, file) end

    if #file_list > 0 then
        local inject_count = 0
        for _, file_path in ipairs(file_list) do
            local abs_path = vim.fn.fnamemodify(file_path, ":p")
            local uri = vim.uri_from_fname(abs_path)
            local ok, lines = pcall(vim.fn.readfile, abs_path)
            if ok and lines then
                clangd.notify("textDocument/didOpen", {
                    textDocument = {
                        uri = uri,
                        languageId = "cpp",
                        version = 1,
                        text = table.concat(lines, "\n")
                    }
                })
                inject_count = inject_count + 1
            end
            if inject_count >= 15 then break end
        end
    end

    vim.defer_fn(function()
        vim.schedule(function()
            local params = vim.lsp.util.make_position_params(0, "utf-16")
            params.context = { includeDeclaration = true }
            
            clangd.request("textDocument/references", params, function(err, result)
                if err or not result or #result == 0 then
                    vim.notify("SmartRef: No semantic references found.", vim.log.levels.WARN)
                    return
                end
                
                -- MANUALLY format and open FZF-Lua to guarantee it displays
                local entries = {}
                for _, loc in ipairs(result) do
                    table.insert(entries, format_lsp_loc(loc))
                end

                require('fzf-lua').fzf_exec(entries, {
                    prompt = "SmartRef> ",
                    winopts = { title = " Smart References: " .. word .. " " },
                    actions = {
                        ["default"] = require('fzf-lua').actions.file_edit,
                        ["ctrl-q"] = require('fzf-lua').actions.file_sel_to_qf,
                    },
                    previewer = "builtin",
                })
            end, bufnr)
        end)
    end, 1200) 
end

return M
