-- lua/overseer/template/user/custom_tasks.lua
return {
  name = "Custom Tasks",
  generator = function(opts, cb)
    local tasks = {
      {
        name = "C++: Generate compile_commands",
        builder = function()
          return {
            cmd = { "./src/scripts/gen_compile_commands.sh" },
            -- Using a minimalist component to keep it quiet
            components = { "default", { "on_output_quickfix", open = false } },
          }
        end,
        condition = {
          callback = function()
            return vim.fn.filereadable("./src/scripts/gen_compile_commands.sh") == 1
          end,
        },
      },
      {
        name = "Project: Rebuild (gcc Debug)",
        builder = function()
          return {
            cmd = { "./rebuild.sh", "gcc", "Debug" },
            components = { "default", { "on_output_quickfix", open = true } },
          }
        end,
        condition = {
          callback = function()
            return vim.fn.filereadable("./rebuild.sh") == 1
          end,
        },
      },
      {
        name = "Git: Clang-Format (Changed Lines)",
        builder = function()
          return {
            cmd = { "git", "clang-format" },
            components = { "default", "on_result_diagnostics" },
          }
        end,
        desc = "Runs git clang-format to only format lines that have been modified",
      },
      {
        name = "Python: Run current file",
        builder = function()
          return {
            cmd = { "python3", vim.fn.expand("%:p") },
            components = { "default", { "on_output_quickfix", open = true } },
          }
        end,
        condition = { filetype = { "python" } },
      },
      {
        name = "Docker: Compose Up",
        builder = function()
          return {
            cmd = { "docker-compose", "up", "-d" },
            components = { "default" },
          }
        end,
        condition = {
          callback = function()
            return vim.fn.filereadable("docker-compose.yml") == 1 or vim.fn.filereadable("docker-compose.yaml") == 1
          end,
        },
      },
    }
    cb(tasks)
  end,
}
