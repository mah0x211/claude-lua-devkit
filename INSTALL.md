# claude-lua-devkit Installation

You will install the claude-lua-devkit components into the current Lua project.

## Overview

Before starting installation, ask user: "Should I continue in English, or would you prefer another language?"

Based on user response:
- IF user responds in English or says English is fine: Continue in English
- IF user responds in another language or requests a specific language: Switch to that language for all subsequent messages
- IF unclear: Ask for clarification in both English and the detected language

Say: "I'll continue in [selected language] for the installation process."

## Step 1: Verify Prerequisites

Check if all required commands are available:

```bash
git --version
```
IF git is not found:
- Tell user: "Git is required but not found. Please install Git first."
- ABORT installation

```bash
find --version 2>/dev/null || find . -maxdepth 0 -name "." 2>/dev/null
```
IF find is not found or doesn't work:
- Tell user: "find command is required but not working. Please check your system."
- ABORT installation

```bash
command -v install >/dev/null 2>&1 && echo "install available" || command -v ginstall >/dev/null 2>&1 && echo "ginstall available"
```
IF neither install nor ginstall is found:
- Tell user: "install command is required but not found. Please install coreutils or check your system."
- ABORT installation

```bash
mkdir --version 2>/dev/null || mkdir -p .tmp/test && rmdir .tmp/test 2>/dev/null
```
IF mkdir is not working:
- Tell user: "mkdir command is required but not working. Please check your system."
- ABORT installation

Say: "✓ All required commands are available"

## Step 2: Confirm Project Directory

Show current directory:
```bash
pwd
```

Ask user: "Installing claude-lua-devkit in [current directory]. Is this your Lua project root? (y/N)"

IF user says no:
- Ask: "Please navigate to your project root directory and run this installation again."
- ABORT installation

## Step 3: Create .claude Directory

Check if .claude directory exists:
```bash
ls -la .claude 2>/dev/null
```

IF .claude directory does NOT exist:
- Say: "Creating .claude directory..."
- Run:
```bash
mkdir -p .claude
```

IF .claude directory already exists:
- Say: "Found existing .claude directory"

## Step 4: Check for Existing Installation

Check for existing installation and version:
```bash
ls -la .claude/memories .claude/commands .claude/ldk-resources 2>/dev/null | head -5
```

IF components exist, check version info:
```bash
grep "^# INSTALL_VERSION=" .claude/commands/ldk/version.md 2>/dev/null | cut -d'=' -f2
```

IF version command exists and has version info:
- Parse current version from the version command
- Say: "Found existing claude-lua-devkit installation (version: [current_version])"
- Ask: "Do you want to update, merge, or cancel? (u/m/c)"
  - u = Update (replace all files)
  - m = Merge (preserve local changes, update only toolkit files)
  - c = Cancel installation

IF version command does NOT exist or has no version info but components exist:
- Say: "Found existing claude-lua-devkit components (version unknown)"
- Ask: "Do you want to update/overwrite the existing installation? (y/N)"
- IF user says no: ABORT with message "Installation cancelled. Existing files preserved."

IF no components exist:
- Say: "No existing installation found. Proceeding with fresh installation."

## Step 5: Install Components

Say: "Installing claude-lua-devkit components..."

### Create temporary directory:
```bash
mkdir -p .tmp
```

### Clone the repository and check versions:
Say: "Cloning claude-lua-devkit repository to check available versions..."
```bash
git clone https://github.com/mah0x211/claude-lua-devkit.git .tmp/claude-lua-devkit
```

IF clone fails:
- Say: "Failed to clone repository. Please check your internet connection."
- Run cleanup: `rm -rf .tmp/claude-lua-devkit`
- ABORT installation

### Check available versions:
```bash
cd .tmp/claude-lua-devkit && git tag -l 'v*' | sort -V
```

IF version tags are found:
- Say: "Available versions:"
- Show the list of version tags
- Say: "Latest version: master (development)"
- Ask: "Which version would you like to install? Enter version tag (e.g., v1.0.0) or press Enter for latest (master):"

IF user enters a version tag:
- Validate the tag exists:
```bash
git tag -l | grep -x "$USER_VERSION"
```
- IF tag exists:
  ```bash
  git checkout "$USER_VERSION"
  ```
  Say: "✓ Switched to version $USER_VERSION"
- IF tag does NOT exist:
  Say: "Version $USER_VERSION not found. Using latest (master)"

IF no version tags found or user pressed Enter:
- Say: "Using latest version (master)"

### Install/Update components based on user choice:

IF user chose UPDATE (u) or FRESH INSTALL:
Say: "Installing components (will replace existing files)..."

```bash
cp -r .tmp/claude-lua-devkit/memories .claude/
```
IF successful, say: "✓ Memory files installed"

```bash
cp -r .tmp/claude-lua-devkit/commands .claude/
```
IF successful, say: "✓ Command files installed"

```bash
cp -r .tmp/claude-lua-devkit/ldk-resources .claude/
```
IF successful, say: "✓ Resource files installed"

IF user chose MERGE (m):
Say: "Merging components (overwriting same-named files, preserving others)..."

```bash
# Simple merge: overwrite same-named files, leave everything else
# Use install command for better file installation semantics

# Detect available install command (GNU coreutils vs BSD)
if command -v ginstall >/dev/null 2>&1; then
    INSTALL_CMD="ginstall"
else
    INSTALL_CMD="install"
fi

# memories: install new files, overwriting any with same names
find .tmp/claude-lua-devkit/memories -name "*.md" -exec $INSTALL_CMD -m 644 {} .claude/memories/ \;

# commands: replace vendor directory completely, leave user files in root
rm -rf .claude/commands/ldk
mkdir -p .claude/commands/ldk
find .tmp/claude-lua-devkit/commands -name "*.md" -exec sh -c '
    target=".claude/commands/${1#.tmp/claude-lua-devkit/commands/}"
    mkdir -p "$(dirname "$target")"
    '"$INSTALL_CMD"' -m 644 "$1" "$target"
' _ {} \;

# ldk-resources: install new files, overwriting any with same names
find .tmp/claude-lua-devkit/ldk-resources -type f -exec sh -c '
    target=".claude/ldk-resources/${1#.tmp/claude-lua-devkit/ldk-resources/}"
    mkdir -p "$(dirname "$target")"
    '"$INSTALL_CMD"' -m 644 "$1" "$target"
' _ {} \;
```

Say: "✓ Components merged:"
Say: "  • Same-named files overwritten with new versions"
Say: "  • Other files preserved unchanged"
Say: "  • commands/ldk/ completely replaced (vendor directory)"

### Record installation version:
Say: "Recording installation version..."

Get version information:
```bash
cd .tmp/claude-lua-devkit
INSTALLED_VERSION=$(git describe --tags --exact-match 2>/dev/null || echo "master")
INSTALLED_COMMIT=$(git rev-parse HEAD)
INSTALL_DATE=$(date -u '+%Y-%m-%d %H:%M:%S UTC')
```

### Create/Update version command with installation info:
Say: "Creating/updating version management command with current installation info..."

```bash
# Create ldk commands directory if it doesn't exist
mkdir -p ../../.claude/commands/ldk

# Generate version command from template
sed -e "s/INSTALL_VERSION=development/INSTALL_VERSION=$INSTALLED_VERSION/g" \
    -e "s/INSTALL_COMMIT=HEAD/INSTALL_COMMIT=$INSTALLED_COMMIT/g" \
    -e "s/INSTALL_DATE=Not installed via INSTALL.md/INSTALL_DATE=$INSTALL_DATE/g" \
    ../../.tmp/claude-lua-devkit/ldk-resources/version-template.md > ../../.claude/commands/ldk/version.md
```
Say: "✓ Version command created/updated with current installation info"

### Clean up temporary files:
```bash
cd ../.. && rm -rf .tmp/claude-lua-devkit
```
Say: "✓ Temporary files cleaned up"

## Step 6: Check CLAUDE.md Status

Check if CLAUDE.md exists in project root:
```bash
ls -la CLAUDE.md 2>/dev/null
```

IF CLAUDE.md does NOT exist:
- Say: "📝 CLAUDE.md not found"
- Say: "  CLAUDE.md helps Claude Code understand your project context."
- Say: "  You can create it later with the /init command"

IF CLAUDE.md already exists:
- Say: "✓ Found existing CLAUDE.md"

## Step 7: Verify Installation

Say: "Verifying installation..."

List installed components:
```bash
ls -la .claude/ | grep -E "memories|commands|ldk-resources"
```

Count installed memory files:
```bash
ls .claude/memories/*.md 2>/dev/null | wc -l
```

IF count is 9 or more:
- Say: "✓ Installation verified: All memory files installed successfully"
ELSE:
- Say: "⚠ Warning: Expected 9 memory files, found [count]"

## Step 8: Installation Complete

Say: "Installation complete! claude-lua-devkit is now installed in your project."

Tell user:
```
Installation Summary:
✓ Memory files installed in .claude/memories/
✓ Command templates installed in .claude/commands/
✓ Build resources installed in .claude/ldk-resources/
✓ Version information embedded in version command

Available Commands:
• /commands/ldk/setup [package] [user] - Set up build system
• /commands/ldk/version - Show version info
• /commands/ldk/version list - List available versions
• /commands/ldk/version update - Update to latest

Next steps:
1. Claude Code will automatically use the memory files for Lua development guidance
2. To create project context: Use /init command
3. To set up the build system: /commands/ldk/setup mylib johndoe
4. To check version anytime: /commands/ldk/version

The toolkit is now ready to use!
```


## Advanced: Non-Interactive Version Selection

IF you want to install a specific version without prompts:

```bash
# For specific version
INSTALL_VERSION="v1.0.0"
git clone https://github.com/mah0x211/claude-lua-devkit.git .tmp/claude-lua-devkit
cd .tmp/claude-lua-devkit && git checkout "$INSTALL_VERSION"
cd ../.. && cp -r .tmp/claude-lua-devkit/{memories,commands,ldk-resources} .claude/
rm -rf .tmp/claude-lua-devkit
```

```bash
# For latest release (not master)
git clone https://github.com/mah0x211/claude-lua-devkit.git .tmp/claude-lua-devkit
cd .tmp/claude-lua-devkit && git checkout $(git tag -l 'v*' | sort -V | tail -1)
cd ../.. && cp -r .tmp/claude-lua-devkit/{memories,commands,ldk-resources} .claude/
rm -rf .tmp/claude-lua-devkit
```

## Version Management

After installation, use the version command for all version-related operations:

### Check current version:
```
/commands/ldk/version
```

### List available versions:
```
/commands/ldk/version list
```

### Update to latest version:
```
/commands/ldk/version update
```

### Update to specific version:
```
/commands/ldk/version update v1.0.0
```

The version information is now embedded directly in the version command file, making it self-contained and eliminating the need for separate version tracking files.

## Uninstallation

To remove claude-lua-devkit:
```bash
rm -rf .claude/memories .claude/commands .claude/ldk-resources
```

IF .claude directory is empty after removal:
```bash
rmdir .claude
```
