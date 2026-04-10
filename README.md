# blink-cmp-claude

[blink.cmp](https://github.com/saghen/blink.cmp) completion source for [Claude Code](https://claude.ai/code) prompts.

Provides completions for:

- `/` slash commands (built-in + custom)
- `@` file mentions

## Installation

### lazy.nvim

```lua
{
  'saghen/blink.cmp',
  dependencies = {
    {
      'saiashirwad/blink-cmp-claude',
      opts = {},
    },
  },
  opts = {
    sources = {
      default = { 'lsp', 'path', 'snippets' },
      per_filetype = {
        claudeprompt = { 'claude-slash', 'claude-files', 'path' },
      },
      providers = {
        ['claude-slash'] = {
          module = 'blink-cmp-claude.slash',
          name = 'Claude',
          score_offset = 100,
        },
        ['claude-files'] = {
          module = 'blink-cmp-claude.files',
          name = 'Files',
          score_offset = 90,
        },
      },
    },
  },
}
```

## Usage

1. In Claude Code, press `Ctrl+G` to open prompt in Neovim
2. Run `:ClaudePromptMode` to enable completions
3. Type `/` at line start for slash commands
4. Type `@` for file completions

## Configuration

```lua
require('blink-cmp-claude').setup({
  -- filetype for claude prompts
  filetype = 'claudeprompt',

  -- auto-detect patterns (lua patterns)
  patterns = {
    '.*/CLAUDE_.*',
    '.*/claude%-prompt%-.*',
  },

  -- what to discover
  discover = {
    custom_commands = true,  -- ~/.claude/commands/
    skills = true,           -- from CLAUDE.md
    mcp = true,              -- MCP plugins
  },

  -- source options
  sources = {
    slash = { enabled = true, score_offset = 100 },
    files = {
      enabled = true,
      score_offset = 90,
      max_results = 20,          -- max completion items
      search_hidden = false,     -- include hidden files
      search_gitignore = true,   -- respect .gitignore
    },
  },
})
```

## Commands

- `:ClaudePromptMode` - Enable claude completions for current buffer
- `:ClaudeRefreshCommands` - Refresh command list after adding custom commands

## Requirements

- [`fd`](https://github.com/sharkdp/fd) (recommended) or [`rg`](https://github.com/BurntSushi/ripgrep) for fuzzy file matching. Falls back to glob if neither is installed.

## Features

- Fuzzy `@` file matching (e.g., `@java` matches `somedir/path/SomeJava.lua`)
- 45 built-in Claude Code slash commands
- Auto-discovers custom commands from `~/.claude/commands/`
- Auto-discovers skills from `CLAUDE.md`
- Auto-discovers MCP plugins

## License

MIT
