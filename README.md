# claude-lua-devkit

A comprehensive Lua development toolkit for Claude Code, including memory files, setup commands, and build system templates.

## What's Included

- **Memory Files** (`memories/`) - Development guidelines and best practices for Claude Code
- **Setup Commands** (`commands/ldk/`) - Claude prompt templates for tool integration  
- **Build Templates** (`ldk-resources/`) - Complete Lua package build system supporting pure Lua, C/C++ extensions, git submodules, and mixed projects

## Installation

Simply ask Claude:
```
Please install claude-lua-devkit by following the instructions at:
https://github.com/mah0x211/claude-lua-devkit/blob/master/INSTALL.md
```

Claude will:
- Check prerequisites and project directory
- Show available versions and let you choose
- Install components safely with verification
- Set up everything ready to use

For advanced use cases or troubleshooting, see [INSTALL.md](INSTALL.md).


## Memory Files Structure

### Central Index
- **`ldk-index.md`** - Master index providing access to all LDK memory files with contextual descriptions

### Core Development Memories
- **`lua-c-api.md`** - Lua C API development: luaopen_* functions, stack operations, userdata creation
- **`lua-module-patterns.md`** - Lua module patterns: return table exports, require() usage, scope management
- **`luarocks-integration.md`** - LuaRocks build system: rockspec structure, dependencies, version management
- **`makefile-patterns.md`** - Makefile development: compiler flags, library linking, cross-platform support

### Build System Memories  
- **`build-system-design.md`** - Advanced build architecture: mixed Lua/C/C++ projects, module grouping
- **`cross-platform-building.md`** - Cross-platform considerations: compiler detection, platform-specific flags

### Project Structure Memories
- **`project-layout.md`** - Standard project structure: src/ for C code, lua/ for Lua modules, spec/ for tests
- **`file-organization.md`** - File organization: naming conventions, directory hierarchies

### Testing and Quality
- **`testing-strategies.md`** - Testing strategies: busted framework, C extension testing, CI/CD setup

### How Memory Files Work
1. **Centralized Access** - Reference `@.claude/memories/ldk-index.md` in your CLAUDE.md
2. **On-Demand Loading** - Claude Code loads specific memory files based on context
3. **Token Efficiency** - Only relevant memories are accessed, reducing token usage


## Available Development Tools

### Lua Package Build System
- **Setup Command**: `/commands/ldk/setup [package-name]`
- **Templates**: `ldk-resources/Makefile`, `ldk-resources/makemk.lua`, `ldk-resources/template.rockspec`
- **Purpose**: Complete Lua package build system with LuaRocks integration, git submodule support, and coverage support
- **Features**: Automatic file discovery, submodule initialization, environment isolation, mixed language support
- **Documentation**: `ldk-resources/BUILD_SYSTEM_GUIDE.md`

### Version Management
- **Version Command**: `/commands/ldk/version [action]`
- **Actions**: `current`, `list`, `update [version]`
- **Purpose**: Track installation version, list available versions, and update toolkit
- **Features**: Safe updates with merge options, version tracking, remote version listing


## Commands Directory

The `commands/` directory contains Claude prompt templates that guide the setup and configuration of development tools. These templates provide structured instructions that Claude follows to integrate specific tools into existing projects.

### Usage Pattern
1. User invokes Claude command: `/commands/ldk/setup`
2. Claude reads the prompt template from `commands/ldk/setup.md`
3. Claude executes the instructions interactively with the user
4. Tools are configured and integrated into the project automatically

### Design Philosophy
- **Template-Based** - Structured prompts guide Claude's actions
- **Interactive** - Claude asks users for configuration details  
- **Non-Intrusive** - Users choose which tools to integrate
- **Resource-Separated** - Templates and files stored in `ldk-resources/`

## Directory Structure

- **`commands/ldk/`** - Claude prompt templates for tool setup
- **`ldk-resources/`** - Lua-specific template files and configuration resources
- **`memories/`** - Universal development guidelines

This separation ensures clear distinction between processes (Claude commands) and files (resources).

## Using with Claude Code

When the `.claude/memories/` directory exists in your project, Claude Code automatically references these files to provide appropriate Lua development support tailored to your project.

### Available Commands

After installation, you can use these Claude commands:

**Build System Setup:**
```
/commands/ldk/setup [package-name]
```
Example: `/commands/ldk/setup mylib`

**Version Management:**
```
/commands/ldk/version                 # Show current version
/commands/ldk/version list           # List available versions  
/commands/ldk/version update         # Update to latest
/commands/ldk/version update v1.0.0  # Update to specific version
```


### What You Get

The toolkit provides:
- **Memory Files** - Automatic guidance for Lua development
- **Interactive Commands** - AI-assisted tool configuration
- **Build Templates** - Production-ready build system
- **Version Management** - Easy updates and version tracking

## License

MIT License - See [LICENSE](LICENSE) file for details.

## Contributing

Contributions are freely welcome! Feel free to:
- Fork the repository and make improvements
- Submit pull requests with bug fixes or enhancements
- Add new memory files or improve existing ones
- Update documentation and examples
- Share your own Lua development patterns and best practices

No formal approval process required - if it improves Lua development with Claude Code, it's likely valuable.

