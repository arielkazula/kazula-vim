-- lua/core/fzf_utils.lua ---------------------------------------------
-- Advanced chained pickers for fzf-lua.

local M = {}

--- Prompt for a directory, then run a picker inside it.
--- @param picker_type "files" | "live_grep" The picker to run after choosing the dir.
function M.pick_dir_then_search(picker_type)
    local fzf = require('fzf-lua')
    
    fzf.directories({
        prompt = "Select Folder❯ ",
        winopts = { title = " 1. Select Target Folder " },
        actions = {
            ["default"] = function(selected)
                -- selected[1] is the directory path
                local dir = selected[1]
                
                -- Trigger the second picker in the selected directory
                if picker_type == "files" then
                    fzf.files({ 
                        cwd = dir, 
                        winopts = { title = " 2. Files in: " .. dir } 
                    })
                elseif picker_type == "live_grep" then
                    fzf.live_grep({ 
                        cwd = dir, 
                        winopts = { title = " 2. Grep in: " .. dir } 
                    })
                end
            end
        }
    })
end

--- A hierarchical file browser that allows "drilling down" into folders.
--- Selecting a folder refreshes the view to its contents.
--- Selecting a file opens it.
function M.file_driller(current_dir)
    local fzf = require('fzf-lua')
    current_dir = current_dir or vim.uv.cwd()
    
    fzf.fzf_exec("ls -1p " .. current_dir, {
        prompt = vim.fn.fnamemodify(current_dir, ":.") .. "> ",
        winopts = { title = " Drill Down: " .. vim.fn.fnamemodify(current_dir, ":p:~") },
        actions = {
            ["default"] = function(selected)
                local entry = selected[1]
                local full_path = current_dir .. "/" .. entry
                
                -- Remove trailing slash for directory check
                local clean_path = full_path:gsub("/$", "")
                
                if vim.fn.isdirectory(clean_path) == 1 then
                    -- If it's a directory, drill down (recursive call)
                    M.file_driller(clean_path)
                else
                    -- If it's a file, open it
                    vim.cmd("edit " .. clean_path)
                end
            end,
            -- Go back up
            ["ctrl-u"] = function()
                local parent = vim.fn.fnamemodify(current_dir, ":h")
                M.file_driller(parent)
            end,
            -- Switch to recursive search in this folder
            ["ctrl-s"] = function()
                fzf.files({ cwd = current_dir, winopts = { title = " Recursive Search: " .. current_dir } })
            end
        }
    })
end

return M
