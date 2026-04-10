# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Neovim plugin that provides [blink.cmp](https://github.com/saghen/blink.cmp) completion sources for Claude Code prompts. Pure Lua, no external dependencies or build step.

## Architecture

- Two blink.cmp sources: `slash` (trigger `/`) and `files` (trigger `@`)
- Both implement the blink.cmp source protocol (`new`, `enabled`, `get_trigger_characters`, `get_completions`)
- Everything is gated on the `claudeprompt` filetype
- Discovery module reads custom commands, skills, and MCP tools from `~/.claude/` at runtime
- Entry point: `require('blink-cmp-claude')` → `lua/blink-cmp-claude/init.lua`

## Development

- No tests, linter, formatter, or CI — changes are tested manually in Neovim
- Keep consistent with existing code style
