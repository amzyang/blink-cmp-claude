local M = {}

local builtin = require('blink-cmp-claude.commands')

local function parse_frontmatter(file, max_lines)
  local lines = vim.fn.readfile(file, '', max_lines or 15)
  local desc = ''
  local hint = nil
  local in_frontmatter = false
  local desc_multiline = false
  for _, line in ipairs(lines) do
    if line == '---' then
      if in_frontmatter then break end
      in_frontmatter = true
    elseif in_frontmatter then
      if desc_multiline then
        local indented = line:match('^%s+(.+)$')
        if indented then
          desc = indented
        end
        desc_multiline = false
      end
      local d = line:match('^description:%s*(.+)$')
      if d then
        if d == '|' or d == '|-' or d == '|+' then
          desc_multiline = true
        else
          desc = d:match('^"(.*)"$') or d:match("^'(.*)'$") or d
        end
      end
      local h = line:match('^argument%-hint:%s*(.+)$')
      if h then
        hint = h:match('^"(.*)"$') or h:match("^'(.*)'$") or h
      end
    end
  end
  return { desc = desc, hint = hint }
end

local function discover_custom_commands(config)
  if not config.discover.custom_commands then
    return {}
  end

  local commands = {}
  local dirs = {
    vim.fn.expand('~/.claude/commands'),
    vim.fn.getcwd() .. '/.claude/commands',
  }

  for _, dir in ipairs(dirs) do
    if vim.fn.isdirectory(dir) == 1 then
      local files = vim.fn.glob(dir .. '/**/*.md', false, true)
      for _, file in ipairs(files) do
        local name = vim.fn.fnamemodify(file, ':t:r')
        local fm = parse_frontmatter(file)
        table.insert(commands, { name = name, desc = fm.desc, hint = fm.hint, custom = true })
      end
    end
  end

  return commands
end

local function discover_skills(config)
  if not config.discover.skills then
    return {}
  end

  local skills = {}
  local dirs = {
    vim.fn.expand('~/.claude/skills'),
    vim.fn.getcwd() .. '/.claude/skills',
  }

  for _, dir in ipairs(dirs) do
    if vim.fn.isdirectory(dir) == 1 then
      local files = vim.fn.glob(dir .. '/*/SKILL.md', false, true)
      for _, file in ipairs(files) do
        local name = vim.fn.fnamemodify(vim.fn.fnamemodify(file, ':h'), ':t')
        local fm = parse_frontmatter(file)
        table.insert(skills, { name = name, desc = fm.desc, hint = fm.hint, skill = true })
      end
    end
  end

  return skills
end

local function discover_plugins(config)
  if not config.discover.plugins then
    return {}
  end

  local items = {}
  local json_path = vim.fn.expand('~/.claude/plugins/installed_plugins.json')
  if vim.fn.filereadable(json_path) == 0 then
    return items
  end

  local content = table.concat(vim.fn.readfile(json_path), '\n')
  local ok, data = pcall(vim.json.decode, content)
  if not ok or not data or not data.plugins then
    return items
  end

  local seen_paths = {}
  for key, entries in pairs(data.plugins) do
    local plugin_name = key:match('^(.+)@')
    if not plugin_name then goto continue end

    for _, entry in ipairs(entries) do
      local install_path = entry.installPath
      if not install_path or seen_paths[install_path] or vim.fn.isdirectory(install_path) == 0 then
        goto next_entry
      end
      seen_paths[install_path] = true

      local skill_files = vim.fn.glob(install_path .. '/skills/*/SKILL.md', false, true)
      for _, file in ipairs(skill_files) do
        local skill_name = vim.fn.fnamemodify(vim.fn.fnamemodify(file, ':h'), ':t')
        local fm = parse_frontmatter(file)
        table.insert(items, {
          name = plugin_name .. ':' .. skill_name,
          desc = fm.desc,
          hint = fm.hint,
          plugin = true,
        })
      end

      local cmd_files = vim.fn.glob(install_path .. '/commands/*.md', false, true)
      for _, file in ipairs(cmd_files) do
        local cmd_name = vim.fn.fnamemodify(file, ':t:r')
        local fm = parse_frontmatter(file)
        table.insert(items, {
          name = plugin_name .. ':' .. cmd_name,
          desc = fm.desc,
          hint = fm.hint,
          plugin = true,
        })
      end

      ::next_entry::
    end
    ::continue::
  end

  return items
end

function M.get_all_commands(config)
  local all = vim.deepcopy(builtin)
  vim.list_extend(all, discover_custom_commands(config))
  vim.list_extend(all, discover_skills(config))
  vim.list_extend(all, discover_plugins(config))
  return all
end

return M
