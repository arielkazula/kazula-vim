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

return M
