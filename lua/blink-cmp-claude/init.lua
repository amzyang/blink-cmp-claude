local M = {}

M.config = nil

local defaults = {
  filetype = 'claudeprompt',
  patterns = {
    '.*/CLAUDE_.*',
    '.*/claude%-prompt%-.*',
  },
  discover = {
    custom_commands = true,
    skills = true,
    plugins = true,
  },
  sources = {
    slash = { enabled = true, score_offset = 100 },
    files = {
      enabled = true,
      score_offset = 90,
      max_results = 20,
      search_hidden = false,
      search_gitignore = true,
    },
  },
}

function M.setup(opts)
  M.config = vim.tbl_deep_extend('force', defaults, opts or {})

  local patterns = {}
  for _, pattern in ipairs(M.config.patterns) do
    patterns[pattern] = M.config.filetype
  end
  vim.filetype.add({ pattern = patterns })

  vim.api.nvim_create_user_command('ClaudePromptMode', function()
    vim.bo.filetype = M.config.filetype
  end, { desc = 'Enable Claude prompt completions' })

  -- inherit markdown syntax/treesitter for claudeprompt filetype
  vim.api.nvim_create_autocmd('FileType', {
    pattern = M.config.filetype,
    callback = function()
      vim.bo.syntax = 'markdown'
      pcall(vim.treesitter.start, 0, 'markdown')
    end,
  })

  vim.api.nvim_create_user_command('ClaudeRefreshCommands', function()
    local slash = require('blink-cmp-claude.slash')
    slash.commands = require('blink-cmp-claude.discovery').get_all_commands(M.config)
    print('Claude commands refreshed')
  end, { desc = 'Refresh Claude command list' })
end

return M
