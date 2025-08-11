# Lua Development Kit Memory Index

Central reference point for all LDK memory files.

## Core Development Memories

@.claude/memories/lua-c-api.md - Lua C API development: luaopen_* functions, stack operations, userdata creation, and proper error handling with lua_error()
@.claude/memories/lua-module-patterns.md - Lua module development patterns: return table exports, require() usage, local vs global scope, and module initialization
@.claude/memories/luarocks-integration.md - LuaRocks build system: rockspec file structure, build dependencies, installation paths, and version management
@.claude/memories/makefile-patterns.md - Makefile development for Lua C extensions: compiler flags, library linking, installation rules, and cross-platform compatibility

## Build System Memories

@.claude/memories/build-system-design.md - Advanced build system architecture: mixed Lua/C/C++ projects, module grouping, SECONDEXPANSION patterns, and dynamic target generation
@.claude/memories/cross-platform-building.md - Cross-platform build considerations: compiler detection, platform-specific flags, library extensions (.so/.dll), and installation paths

## Project Structure Memories

@.claude/memories/project-layout.md - Standard Lua project structure: src/ for C code, lib/ for Lua modules, spec/ for tests, and proper file organization
@.claude/memories/file-organization.md - File organization best practices: module naming conventions, directory hierarchies, and separation of concerns

## Testing and Quality

@.claude/memories/testing-strategies.md - Testing strategies for Lua projects: busted framework, spec files, C extension testing, and continuous integration setup

## Usage

This index provides targeted access to LDK memory files based on development context.
Reference in CLAUDE.md with: `@.claude/memories/ldk-index.md`