# Lua Package Build System Guide

**Complete build system for Lua packages supporting pure Lua modules, C/C++ extensions, command scripts, and mixed projects with LuaRocks integration and coverage support.**

## Interactive Setup

```bash
#!/bin/bash
# From your project root directory

# Interactive configuration
echo "=== Lua Makefile Setup ==="
echo

# Get package name
read -p "Enter package name (e.g., mylib): " PACKAGE_NAME
if [ -z "$PACKAGE_NAME" ]; then
    echo "Error: Package name is required"
    exit 1
fi

# Get GitHub username
read -p "Enter GitHub username: " GITHUB_USER
if [ -z "$GITHUB_USER" ]; then
    echo "Error: GitHub username is required"
    exit 1
fi

# Convert package name to uppercase for coverage flags
PACKAGE_NAME_UPPER=$(echo "$PACKAGE_NAME" | tr '[:lower:]' '[:upper:]')

echo
echo "Configuration:"
echo "  Package name: $PACKAGE_NAME"
echo "  GitHub user:  $GITHUB_USER"
echo "  Coverage flag: ${PACKAGE_NAME_UPPER}_COVERAGE"
echo
read -p "Continue? (y/N): " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Setup cancelled"
    exit 0
fi

echo
echo "Generating files..."

# Generate customized templates
sed -e "s/{{PACKAGE_NAME}}/$PACKAGE_NAME/g" \
    -e "s/{{PACKAGE_NAME_UPPER}}/$PACKAGE_NAME_UPPER/g" \
    .claude/ldk-resources/Makefile > Makefile
echo "✓ Makefile generated"

# Copy makemk.lua (no customization needed)
cp .claude/ldk-resources/makemk.lua .
echo "✓ makemk.lua copied"

# Create rockspecs directory if it doesn't exist
mkdir -p rockspecs

# Generate customized rockspec
sed -e "s/{{PACKAGE_NAME}}/$PACKAGE_NAME/g" \
    -e "s/{{GITHUB_USER}}/$GITHUB_USER/g" \
    .claude/ldk-resources/template.rockspec > "rockspecs/$PACKAGE_NAME-dev-1.rockspec"
echo "✓ rockspecs/$PACKAGE_NAME-dev-1.rockspec generated"

# Template files remain in .claude/ for future use

echo
echo "Setup complete! Your build system is ready."
echo "Usage:"
echo "  luarocks make rockspecs/$PACKAGE_NAME-dev-1.rockspec    # Build and install"
echo "  ${PACKAGE_NAME_UPPER}_COVERAGE=1 luarocks make rockspecs/$PACKAGE_NAME-dev-1.rockspec    # Build with coverage"
```

## What This Provides

- **Complete Lua Package System** - Supports pure Lua modules, C/C++ extensions, and command scripts
- **Automatic File Discovery** - Scans `lib/`, `src/`, and `bin/` directories automatically
- **LuaRocks Integration** - Seamless integration with LuaRocks package management
- **Mixed Language Support** - Automatic handling of C and C++ files in same project
- **Coverage Support** - Build with gcov instrumentation for C/C++ code and luacov for Lua code
- **Clean Development Workflow** - Organized build, install, and clean targets
- **Automatic Compiler Selection** - Uses appropriate compiler based on file type
- **Module Grouping** - Groups related source files by prefix into single modules

## Alternative: Manual Setup

If you prefer manual configuration:

```bash
# Set variables manually
PACKAGE_NAME="your-package-name"
GITHUB_USER="your-github-username"
PACKAGE_NAME_UPPER=$(echo "$PACKAGE_NAME" | tr '[:lower:]' '[:upper:]')

# Generate files
sed -e "s/{{PACKAGE_NAME}}/$PACKAGE_NAME/g" \
    -e "s/{{PACKAGE_NAME_UPPER}}/$PACKAGE_NAME_UPPER/g" \
    .claude/ldk-resources/Makefile > Makefile

cp .claude/ldk-resources/makemk.lua .

sed -e "s/{{PACKAGE_NAME}}/$PACKAGE_NAME/g" \
    -e "s/{{GITHUB_USER}}/$GITHUB_USER/g" \
    .claude/ldk-resources/template.rockspec > "rockspecs/$PACKAGE_NAME-dev-1.rockspec"

# Template files remain in .claude/ for future use
```

## File Structure Created

After setup, your project will have:
- `Makefile` - Main build configuration (customized for your package)
- `makemk.lua` - Module discovery script
- `rockspecs/your-package-dev-1.rockspec` - LuaRocks package specification (customized)
- `mk/modules.mk` - Generated module definitions (created during first build)

## Integration with Testing

This build system integrates with the testing workflows described in:
- `.claude/memories/ldk-commands.md` - General development commands
- `.claude/memories/ldk-c-coverage.md` - C extension coverage procedures

## Requirements

- LuaRocks for Lua package management
- GCC or compatible C compiler for C extensions
- G++ or compatible C++ compiler for C++ extensions (optional)
- Standard Unix tools (make, install, etc.)

### Compiler Configuration
- **C Compiler**: Automatically uses `$(CC)` from LuaRocks environment
- **C++ Compiler**: Automatically derives from `$(CC)` (gcc→g++, clang→clang++)
- **Flags**: Inherits all SDK and platform settings from LuaRocks configuration

## Template Variables

The setup process replaces the following template variables:

### Required Variables
- `PACKAGE_NAME` - Your Lua package name (affects coverage variable names)
- `GITHUB_USER` - Your GitHub username (affects repository URLs)

### Template Replacements
- `{{PACKAGE_NAME_UPPER}}_COVERAGE` → `${PACKAGE_NAME_UPPER}_COVERAGE` in Makefile (uppercase)
- `{{PACKAGE_NAME}}` → `${PACKAGE_NAME}` in rockspec (lowercase)
- `{{GITHUB_USER}}` → `${GITHUB_USER}` in repository URLs

## Advanced Customization

After setup, you can further customize:
- **Rockspec**: Edit package description, dependencies, license
- **Makefile**: Typically works without modification
- **makemk.lua**: Handles automatic source discovery (rarely needs changes)

## Directory Structure

This build system works with the following structure:
```
your-project/
├── lib/                    # Lua modules (.lua files)
│   ├── mypackage.lua      # Main module (optional)
│   └── mypackage/         # Sub-modules (optional)
│       └── helper.lua
├── src/                    # C/C++ extensions (.c, .cpp files)  
│   ├── core.c             # → core.so
│   ├── parser.cpp         # → parser.so  
│   └── utils/             # → utils/*.so
│       └── helper.c
└── bin/                    # Command scripts (.lua files, optional)
    └── mytool.lua         # → executable command
```

### Module Types

**Pure Lua Package**: Only `lib/` directory with `.lua` files
**C/C++ Extension Package**: Only `src/` directory with `.c/.cpp` files  
**Mixed Package**: Both `lib/` and `src/` directories
**Command Package**: Includes `bin/` directory with executable scripts

### Source File Handling

**C Files**: `.c` files are compiled with `$(CC)` (typically gcc/clang)
**C++ Files**: `.cpp` files are compiled with `$(CXX)` (typically g++/clang++)
**Mixed Projects**: Can contain both C and C++ files - the build system automatically:
- Detects file types and uses appropriate compiler
- Links C++ files with `-lstdc++` when needed
- Groups files by prefix (e.g., `foo.c` + `foo_helper.cpp` → single `foo` module)

### Examples

**Pure C Project**:
```
src/
├── parser.c           → parser.so module
└── utils.c           → utils.so module
```

**Pure C++ Project**:
```
src/
├── engine.cpp        → engine.so module (linked with -lstdc++)
└── renderer.cpp      → renderer.so module (linked with -lstdc++)
```

**Mixed C/C++ Project**:
```
src/
├── core.c            → core.so module
├── engine.cpp        → engine.so module (linked with -lstdc++)
└── utils/
    ├── helper.c      → utils/helper.so module  
    └── parser.cpp    → utils/parser.so module (linked with -lstdc++)
```

**Grouped Files**:
```
src/
├── network.c         → All grouped into network.so module
├── network_client.c  → (linked with appropriate compiler)
└── network_server.cpp → (adds -lstdc++ to linker flags)
```