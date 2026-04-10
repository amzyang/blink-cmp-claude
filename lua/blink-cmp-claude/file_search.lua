local M = {}

local function fuzzy_filter(files, query, max_results)
  if not query or query == '' then
    local results = {}
    for i = 1, math.min(#files, max_results) do
      results[i] = files[i]
    end
    return results
  end
  local matched = vim.fn.matchfuzzy(files, query)
  local results = {}
  for i = 1, math.min(#matched, max_results) do
    results[i] = matched[i]
  end
  return results
end

local function command_exists(cmd)
  return vim.fn.executable(cmd) == 1
end

local function search_with_fd_async(query, config, cwd, callback)
  local args = { '--type', 'f', '--type', 'd', '--max-results', '500' }

  if config.search_hidden then
    table.insert(args, '--hidden')
  end
  if not config.search_gitignore then
    table.insert(args, '--no-ignore')
  end

  local stdout = vim.loop.new_pipe(false)
  local stdout_data = ''
  local handle

  handle = vim.loop.spawn('fd', {
    args = args,
    stdio = { nil, stdout, nil },
    cwd = cwd,
  }, vim.schedule_wrap(function()
    stdout:close()
    if handle and not handle:is_closing() then
      handle:close()
    end

    local all_files = {}
    for line in stdout_data:gmatch('([^\n]+)') do
      if line ~= '' then
        table.insert(all_files, line)
      end
    end
    callback(fuzzy_filter(all_files, query, config.max_results))
  end))

  if not handle then
    callback({})
    return nil
  end

  stdout:read_start(vim.schedule_wrap(function(err, data)
    if err then return end
    if data then
      stdout_data = stdout_data .. data
    end
  end))

  return function()
    if handle and not handle:is_closing() then
      handle:close()
    end
    if stdout and not stdout:is_closing() then
      stdout:close()
    end
  end
end

local function search_with_rg_async(query, config, cwd, callback)
  local args = { '--files' }

  if config.search_hidden then
    table.insert(args, '--hidden')
  end
  if not config.search_gitignore then
    table.insert(args, '--no-ignore')
  end

  local stdout = vim.loop.new_pipe(false)
  local stdout_data = ''
  local handle

  handle = vim.loop.spawn('rg', {
    args = args,
    stdio = { nil, stdout, nil },
    cwd = cwd,
  }, vim.schedule_wrap(function()
    stdout:close()
    if handle and not handle:is_closing() then
      handle:close()
    end

    local all_files = {}
    for line in stdout_data:gmatch('([^\n]+)') do
      if line ~= '' then
        table.insert(all_files, line)
      end
    end
    callback(fuzzy_filter(all_files, query, config.max_results))
  end))

  if not handle then
    callback({})
    return nil
  end

  stdout:read_start(vim.schedule_wrap(function(err, data)
    if err then return end
    if data then
      stdout_data = stdout_data .. data
    end
  end))

  return function()
    if handle and not handle:is_closing() then
      handle:close()
    end
    if stdout and not stdout:is_closing() then
      stdout:close()
    end
  end
end

local function search_with_glob_sync(query, cwd, max_results)
  local pattern = cwd .. '/**/' .. query .. '*'
  local matches = vim.fn.glob(pattern, false, true)
  local results = {}
  for i = 1, math.min(#matches, max_results) do
    local rel = matches[i]:sub(#cwd + 2)
    results[i] = rel
  end
  return results
end

function M.search_files_async(query, config, cwd, callback)
  if command_exists('fd') then
    return search_with_fd_async(query, config, cwd, callback)
  elseif command_exists('rg') then
    return search_with_rg_async(query, config, cwd, callback)
  else
    callback(search_with_glob_sync(query, cwd, config.max_results))
    return nil
  end
end

return M
