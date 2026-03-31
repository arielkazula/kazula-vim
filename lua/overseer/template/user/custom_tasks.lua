-- lua/overseer/template/user/custom_tasks.lua
return {
  name = "Custom Tasks",
  generator = function(opts, cb)
    local tasks = {
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
        name = "C++: Generate compile_commands",
        builder = function()
          return {
            cmd = { "./src/scripts/gen_compile_commands.sh" },
            components = { "default", { "on_output_quickfix", open = true } },
          }
        end,
        condition = {
          callback = function()
            return vim.fn.filereadable("./src/scripts/gen_compile_commands.sh") == 1
          end,
        },
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
