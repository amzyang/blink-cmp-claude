local file_search = require('blink-cmp-claude.file_search')

local M = {}

function M.new(opts)
  local self = setmetatable({}, { __index = M })
  local config = require('blink-cmp-claude').config
  self.filetype = config.filetype
  return self
end

function M:enabled()
  return vim.bo.filetype == self.filetype
end

function M:get_trigger_characters()
  return { '@' }
end

function M:get_completions(context, callback)
  local line = context.line
  local col = context.cursor[2]
  local before = line:sub(1, col)

  local at_match = before:match('@([^@%s]*)$')
  if not at_match then
    callback({ items = {}, is_incomplete_forward = false })
    return
  end

  local cwd = vim.fn.getcwd()
  local config = require('blink-cmp-claude').config.sources.files

  local cancel = file_search.search_files_async(at_match, config, cwd, function(files)
    local items = {}
    for i, rel in ipairs(files) do
      local is_dir = vim.fn.isdirectory(cwd .. '/' .. rel) == 1
      table.insert(items, {
        label = '@' .. rel,
        kind = is_dir and vim.lsp.protocol.CompletionItemKind.Folder
          or vim.lsp.protocol.CompletionItemKind.File,
        insertText = '@' .. rel .. (is_dir and '/' or ' '),
        filterText = '@' .. rel,
        sortText = string.format('%04d', i),
      })
    end
    callback({
      items = items,
      is_incomplete_forward = true,
      is_incomplete_backward = true,
    })
  end)

  return cancel
end

return M
