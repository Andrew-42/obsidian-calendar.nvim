# AGENTS.md

_This file provides coding, style, and operational guidelines for agentic or AI code generation agents contributing to this repository. Follow these instructions for consistent, maintainable, and idiomatic code._

---

## 1. Build / Lint / Test Commands

### Formatting
- **Format Lua code with [stylua](https://github.com/JohnnyMorganz/StyLua):**
  ```sh
  stylua .
  ```
  - Uses the repo’s `stylua.toml` (indentation = 4 spaces, preferred double quotes, max column 120).

### Linting
- **Run [luacheck](https://github.com/mpeterv/luacheck) if available:**
  ```sh
  luacheck lua/
  ```
  - Install with `luarocks install luacheck` if necessary.
- _There is currently no `Makefile` or built-in linting runner._

### Testing
- **This repository does _not_ include built-in unit or integration tests.**
- **If you add tests:**
  - Place them under a new `tests/` or `spec/` directory.
  - Use [busted](https://olivinelabs.com/busted/) (common Lua test runner for OpenSource plugins):
    ```sh
    busted tests                  # All tests
    busted tests/foo_spec.lua     # Single test file
    busted --filter 'name'        # Single test (name or pattern match)
    ```
  - Document the test invocation and structure if you introduce tests.

### Neovim Integration
- **Primary workflow is interactive:**
  - Load plugin with a Neovim plugin manager (see README for lazy.nvim instructions)
  - Use the `:ObsidianCalendar` command and keymaps interactively
  - Development and testing typically occur inside Neovim

---

## 2. Code Style Guidelines

### Architecture & Composition
- **Functional, composition-based design:**
  - Build complex behaviors from small, composable functions
  - Minimize mutable/global state (see `CLAUDE.md`)
- **Purity and isolation:**
  - Pure functions preferred; isolate I/O/stateful logic
- **Short, single-purpose functions:**

### Types, Documentation & Comments
- **Type documentation via LuaLS-style docstrings only (as in `--- @param ...`, `--- @return ...`)**
  - _Do not use inline type annotations or non-standard Lua type hints_
- **Minimal comments:**
  - Only document non-obvious logic, edge cases, or contract behavior
  - Do not add comments for trivial code (“self-explanatory code” philosophy)
- **All public interface functions (user module API) should have docstrings with param/return annotations**

### Imports & Module Structure
- Use `local foo = require('foo')` at the top of modules for dependencies
- Each Lua module should define and return a single table (not globals)
- `init.lua` is the user-facing entry point, with main code in submodules

### Formatting (see stylua.toml)
- **Indent: 4 spaces**
- **Max column width:** 120, prefer not to exceed
- **Quote style:** Auto-prefer double quotes
- **No trailing whitespace**
- _Always run `stylua .` before committing/reviewing code_

### Naming Conventions
- **Modules/files:** snake_case (`date_utils.lua`, `file_utils.lua`)
- **Functions:** lower_snake_case for local, PascalCase for constructor-like (e.g. `Date.new`)
- **Variables:**  lower_snake_case unless referencing pure stateless class-like constructs (e.g. `Date`, `MonthDate`)
- **Constants:** use `local` and UPPER_SNAKE_CASE only if needed
- **Tables:** Prefix with `M` for module tables, otherwise descriptive

### Error Handling
- Use `pcall` for safe dynamic requires or calls that may fail
- All user-facing errors/notices must use `vim.notify` with appropriate log level (ERROR, WARN, INFO)
- Do not print directly to stdout/stderr; always use Neovim mechanisms for user feedback
- Check for nil/invalid inputs before calling APIs (see `validate_daily_notes_dir` pattern)

### Keymaps & Neovim API Usage
- Register keymaps buffer-locally when possible
- Use descriptive `desc` for mappings
- Always use `vim.api.nvim_*` functions, not deprecated/unstable APIs
- Document any new Ex commands, autocmds, or options in README and/or help

---

## 3. Design Principles (from CLAUDE.md & Project Structure)
- **Functional Composition:** Write single-purpose functions, combine simply
- **Type Documentation:** Use only LuaLS docstrings for types
- **Minimal Comments:** Favor clear code; comment only when essential
- **Short Functions:** Prefer functions <30 lines; break up complex logic
- **Pure Functions:** Avoid side effects; do I/O in isolated helpers
- **Do not modify global state** unless imperative (buffer/window state, e.g. for UI)

---

## 4. Adding Tests (best practices for new contributions)
- Place Lua tests in `/tests/` or `/spec/` (not present yet)
- Use [busted](https://olivinelabs.com/busted/) or [plenary.nvim/test_harness.lua](https://github.com/nvim-lua/plenary.nvim) for integration
- Name test files as `*_spec.lua` or `*_test.lua`
- Document the test commands in README and AGENTS.md if adding

---

## 5. Conventions for Documentation & New Files

- **Do not create new markdown documentation files** (README, CLAUDE.md) unless specified by user
- If adding plugin help (`:h`) docs, follow Neovim `doc/*.txt` conventions (wrap at 80 chars)
- For new config or support files, use standard patterns (“stylua.toml”, etc.)

---

## 6. Cursor, Copilot & AI
- There are **no `Cursor` or `Copilot` rules**. Follow this file and `CLAUDE.md`.
- Any future `.cursor/rules/` or `.cursorrules` or Copilot instructions should be incorporated here.

---

## Summary for Agents
1. **Run stylua before any commit.**
2. Use `luacheck` for linting if available.
3. If introducing tests, add them to `tests/` and use busted.
4. Follow all architectural and style patterns above.
5. Document any new commands, keymaps, or config in the README and here.

_End of AGENTS.md_
