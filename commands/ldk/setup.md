# Setup Lua C/C++ Build System: $ARGUMENTS

You will set up a complete Lua C/C++ extension build system for the current project.

**Prerequisites**: This command accesses templates from the `.claude/ldk-resources/` directory (installed with this toolkit).

## Step 1: Parse and Validate Arguments

IF $ARGUMENTS contains two space-separated values:
1. Extract package name and GitHub username from $ARGUMENTS
2. Say: "I'll set up build system for package '{package-name}' by user '{github-username}'"
3. Ask: "Continue with these settings? (y/N)"

IF $ARGUMENTS is empty OR user says no:
1. Ask: "Enter package name (e.g., mylib):"
2. Ask: "Enter GitHub username:"

## Step 2: Check for Existing Build Files

Check for existing build files:
```bash
ls Makefile makemk.lua rockspecs/*.rockspec *.rockspec 2>/dev/null | head -5
```

IF any build files exist:
1. Say: "Found existing build files: [list files]"
2. Ask: "Do you want to overwrite these files? This will replace your current build configuration. (y/N)"
3. IF user says no, abort with: "Setup cancelled. Existing build files preserved."

## Step 3: Execute the Setup Script

Run this exact command from the project root directory:
```bash
bash .claude/ldk-resources/setup-makefile.sh "$PACKAGE_NAME" "$GITHUB_USER"
```

## Step 4: Verify Results

After the script completes:
1. Confirm that these files were created:
   - `Makefile`
   - `makemk.lua`  
   - `rockspecs/{package}-dev-1.rockspec`
2. Show the usage instructions from the script output

## Step 5: Final Instructions

Tell the user:
"Setup complete! Your build system supports Pure Lua projects, C/C++ extensions (.c/.cpp files), mixed projects, automatic compiler selection, and coverage instrumentation. Create src/, lib/, and bin/ directories as needed, then use 'luarocks make' to build."
