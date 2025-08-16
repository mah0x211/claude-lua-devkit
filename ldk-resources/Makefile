##
# Lua Package Build System with Automatic Module Discovery
##
#
# PURPOSE:
# This Makefile provides an automated build system for Lua packages that
# contain mixed Lua (.lua) and C/C++ (.c/.cpp) modules. It automatically
# discovers source files and builds them into the appropriate Lua modules.
#
# WHY THIS DESIGN:
# - Traditional Makefiles require manual listing of every source file
# - Module names must match directory structure for Lua's require() system
# - C modules need proper luaopen_* function naming conventions
# - Installation paths must be correct for luarocks package management
#
# KEY FEATURES:
# 1. AUTOMATIC DISCOVERY: Scans src/, lua/, bin/ directories automatically
# 2. PREFIX GROUPING: Groups C files by prefix (foo.c + foo_bar.c → single module)
# 3. NESTED MODULES: Supports directory hierarchy (src/util/parser.c → util.parser)
# 4. MIXED LANGUAGES: Handles C, C++, and Lua files in same project
# 5. LUAROCKS INTEGRATION: Designed to work seamlessly with luarocks build system
# 6. COVERAGE SUPPORT: Built-in support for code coverage analysis
#
# BENEFITS:
# - Zero configuration: Just add files to src/, lua/, bin/ and they're built
# - Maintainable: No need to update Makefile when adding/removing source files
# - Consistent: Enforces proper Lua module naming and structure conventions
# - Portable: Works across different platforms via luarocks
#
# USAGE:
# This Makefile is designed to be used exclusively through 'luarocks make'.
# Direct 'make' execution is prevented to ensure proper variable setup.
#

# Build flags configuration
# Coverage flags (enabled when {{PACKAGE_NAME_UPPER}}_COVERAGE is set)
ifdef {{PACKAGE_NAME_UPPER}}_COVERAGE
COVFLAGS = --coverage
endif


##
# Display build environment information
# These variables are provided by luarocks via rockspec build_variables
##
# PACKAGE_NAME    - Package name (e.g., "example")
# LIB_EXTENSION   - Library extension (e.g., "so" on Linux/macOS, "dll" on Windows)
# LUADIR          - Lua module installation directory (e.g., /usr/local/share/lua/5.1)
# LIBDIR          - C library installation directory (e.g., /usr/local/lib/lua/5.1)
# BINDIR          - Binary/script installation directory (e.g., /usr/local/bin)
# CC              - C compiler command (e.g., "gcc", "clang")
# CXX             - C++ compiler command (e.g., "g++", "clang++")
# CFLAGS          - C compiler flags
# CXXFLAGS        - C++ compiler flags
# WARNINGS        - Warning flags
# CPPFLAGS        - Preprocessor flags
# LDFLAGS         - Linker flags
# PLATFORM_LDFLAGS - Platform-specific linker flags
# Macro to display build environment information
define DISPLAY_BUILD_ENV
$(info ========================================================================)
$(info Phase 1: Build Environment Setup)
$(info ========================================================================)
$(info External Variables from luarocks:)
$(info PACKAGE_NAME: $(PACKAGE_NAME))
$(info LIB_EXTENSION: $(LIB_EXTENSION))
$(info LUADIR: $(LUADIR))
$(info LIBDIR: $(LIBDIR))
$(info BINDIR: $(BINDIR))
$(info CC: $(CC))
$(info CXX (derived): $(CXX))
$(info CFLAGS: $(CFLAGS))
$(info CXXFLAGS: $(CXXFLAGS))
$(info LDFLAGS: $(LDFLAGS))
$(info PLATFORM_LDFLAGS: $(PLATFORM_LDFLAGS))
$(info COVFLAGS: $(COVFLAGS))
$(info ========================================================================)
endef

# Display build environment information only when not running clean
ifeq ($(filter clean,$(MAKECMDGOALS)),)
$(eval $(call DISPLAY_BUILD_ENV))
endif

##
# External variable validation
# Validate required variables provided by luarocks
##
# Allow 'make clean' to run without PACKAGE_NAME
ifeq ($(filter clean,$(MAKECMDGOALS)),)
  ifndef PACKAGE_NAME
    $(error This Makefile must be used through 'luarocks make'. Please run 'luarocks make' instead of 'make' directly.)
  endif
endif

# Validate required external variables (skip for clean target)
ifeq ($(filter clean,$(MAKECMDGOALS)),)
  $(info Validating required external variables...)
  ifndef LIB_EXTENSION
    $(error Required variable LIB_EXTENSION is not set. Check rockspec install_variables.)
  endif
endif
# TEMPORARILY DISABLED FOR TESTING
# ifndef LUADIR
# $(error Required variable LUADIR is not set. Check rockspec install_variables.)
# endif
# ifndef LIBDIR
# $(error Required variable LIBDIR is not set. Check rockspec install_variables.)
# endif
# ifndef BINDIR
# $(error Required variable BINDIR is not set. Check rockspec install_variables.)
# endif


###########################################################################
# Input file discovery and processing
###########################################################################
# Discover command files in bin/ directory
ifeq ($(filter clean,$(MAKECMDGOALS)),)
$(info Discovering command scripts in bin/ directory...)
endif
CMD_SOURCES = $(shell find bin -name '*.lua' 2>/dev/null || true)
CMD_TARGETS = $(patsubst bin/%.lua, $(BINDIR)/%, $(CMD_SOURCES))

# Discover Lua module files in lua/ directory
ifeq ($(filter clean,$(MAKECMDGOALS)),)
$(info Discovering Lua modules in lua/ directory...)
endif
LUASRCS = $(shell find lua -name '*.lua' 2>/dev/null || true)
LUALIBS = $(patsubst lua/%,$(LUALIBDIR)/%,$(filter-out lua/$(PACKAGE_NAME).lua,$(LUASRCS)))
# Set MAINLIB for either Lua or C main module (but not both)
MAINLIB = $(if $(wildcard lua/$(PACKAGE_NAME).lua),$(LUADIR)/$(PACKAGE_NAME).lua,$(if $(filter $(PACKAGE_NAME),$(MODULE_NAMES)),$(LIBDIR)/$(PACKAGE_NAME).$(LIB_EXTENSION)))

###########################################################################
# C module definition generation and processing
# makemk.lua scans src/ directory and groups C/C++ files by prefix to create modules
###########################################################################
ifeq ($(filter install clean,$(MAKECMDGOALS)),)
$(info ========================================================================)
$(info Phase 2: C Module Discovery and Processing)
$(info ========================================================================)
$(info Scanning src/ directory for C/C++ source files...)
MAKEMK_OUTPUT := $(shell lua makemk.lua >&2 && echo "SUCCESS" || echo "FAILED")
ifneq ($(MAKEMK_OUTPUT),SUCCESS)
$(error makemk.lua failed to generate mk/modules.mk. Check the error messages above.)
endif
endif

# Include module definitions (variables and MODULES list)
# Skip loading for clean target since we don't need module definitions
ifeq ($(filter clean,$(MAKECMDGOALS)),)
  $(info Loading generated module definitions from mk/modules.mk...)
endif
#
# MODULE VARIABLE DOCUMENTATION
# =============================
#
# The modules.mk file (generated by makemk.lua) creates variables for each C module:
#
# PREFIX GROUPING: makemk.lua groups files by prefix within each directory
#   src/foo.c, src/foo_bar.c, src/foo_baz.c → single 'foo' module
#   src/bar.c, src/baz.c → separate 'bar' and 'baz' modules
#
# For each module with grouped files, e.g., src/foo.c + src/foo_bar.c + src/foo_baz.c:
#   - Path conversion: src/foo -> foo (/ becomes _)
#   - Generated variables:
#     * foo_SRC  = src/foo.c src/foo_bar.c src/foo_baz.c
#     * foo_OBJS = $(foo_SRC:.c=.o)            # Object files (auto-generated from SRC)
#               := $(foo_OBJS:.cpp=.o)        # Also handles .cpp files
#     * foo_LINK = $(CC) or $(CXX)            # Linker command (CC for C, CXX for C++)
#     * foo_LIBS = [flags]                    # Additional library flags (e.g., -lstdc++)
#   - Lua module: require('<PACKAGE_NAME>.foo')
#
# Nested directory example, e.g., src/foo/bar.c:
#   - Path conversion: src/foo/bar -> foo_bar (/ becomes _)
#   - Generated variables:
#     * foo_bar_SRC  = src/foo/bar.c          # Single source file in subdirectory
#     * foo_bar_OBJS = $(foo_bar_SRC:.c=.o)   # Single object file
#     * foo_bar_LINK = $(CC)                  # Linker command
#     * foo_bar_LIBS =                        # No additional libs
#   - Lua module: require('<PACKAGE_NAME>.foo.bar')
#
# Nested directory with grouping, e.g., src/foo/qux.c + src/foo/qux_helper.c:
#   - Path conversion: src/foo/qux -> foo_qux (/ becomes _)
#   - Generated variables (multiple files grouped into single nested module):
#     * foo_qux_SRC  = src/foo/qux.c src/foo/qux_helper.c
#     * foo_qux_OBJS = $(foo_qux_SRC:.c=.o)   # Multiple object files
#     * foo_qux_LINK = $(CC)                  # Linker command
#     * foo_qux_LIBS =                        # No additional libs
#   - Lua module: require('<PACKAGE_NAME>.foo.qux')
#
# Additionally, modules.mk defines:
#   MODULES = src/foo src/foo/bar src/foo/qux # List of all discovered modules
#
# These variables are used by the static pattern rule with SECONDEXPANSION:
#   $(MODULE_TARGETS): %.$(LIB_EXTENSION): $$($$(subst /,_,$$*)_OBJS)
#
# Example transformations:
#   foo.so     -> foo_OBJS, foo_LINK, foo_LIBS
#   foo/bar.so -> foo_bar_OBJS, foo_bar_LINK, foo_bar_LIBS
#   foo/qux.so -> foo_qux_OBJS, foo_qux_LINK, foo_qux_LIBS
#
# Only include modules.mk if not running clean target
ifeq ($(filter clean,$(MAKECMDGOALS)),)
  -include mk/modules.mk
endif

# Generate target variables and paths from C module definitions
ifeq ($(filter clean,$(MAKECMDGOALS)),)
$(info Generating build targets and installation paths...)
endif
# MODULE_NAMES: extract just the filename (util, helper)
MODULE_NAMES = $(foreach mod,$(MODULES),$(notdir $(mod)))
# MODULE_TARGETS: convert src/util/helper -> src/util/helper.$(LIB_EXTENSION) (same directory as .o files)
MODULE_TARGETS = $(addsuffix .$(LIB_EXTENSION),$(MODULES))
# MODULE_LIBS: full installation paths for C libraries (excluding main module if it's C)
MODULE_LIBS = $(patsubst src/%,$(CLIBDIR)/%,$(addsuffix .$(LIB_EXTENSION),$(filter-out src/$(PACKAGE_NAME),$(MODULES))))

##
# Configuration and validation
ifeq ($(filter clean,$(MAKECMDGOALS)),)
$(info Configuring build environment and validating module setup...)
endif
##
# Installation directory configuration
# LUALIBDIR - Package-specific Lua library directory ($(LUADIR)/$(PACKAGE_NAME))
# CLIBDIR   - Package-specific C library directory ($(LIBDIR)/$(PACKAGE_NAME))
LUALIBDIR = $(LUADIR)/$(PACKAGE_NAME)
CLIBDIR = $(LIBDIR)/$(PACKAGE_NAME)

# Module validation
# Check for main module conflicts - prevent having both lua/package.lua and src/package.c
HAS_MAIN_LUA = $(wildcard lua/$(PACKAGE_NAME).lua)
HAS_MAIN_C = $(filter $(PACKAGE_NAME),$(MODULE_NAMES))

ifneq ($(HAS_MAIN_LUA),)
ifneq ($(HAS_MAIN_C),)
$(error Error: Both Lua main module (lua/$(PACKAGE_NAME).lua) and C main module (src/$(PACKAGE_NAME).c) exist. Please use only one main module type.)
endif
endif

##
# Build targets
##
.PHONY: all install install-commands install-lualibs clean show-vars

# Default target - build all C modules
all: $(MODULE_TARGETS)

##
# Installation rules and macros
##
# Common installation macro - creates directory and copies file
define INSTALL_FILES
	@echo "Installing $< -> $@"
	@echo "Creating directory: $(@D)"
	@mkdir -p "$(@D)"
	@install "$<" "$@"
endef

# Main module installation (either Lua or C)
ifneq ($(MAINLIB),)
# Install Lua main module if it exists
ifneq ($(wildcard lua/$(PACKAGE_NAME).lua),)
$(MAINLIB): lua/$(PACKAGE_NAME).lua
	$(INSTALL_FILES)
else
# Install C main module if it exists
$(MAINLIB): src/$(PACKAGE_NAME).$(LIB_EXTENSION)
	$(INSTALL_FILES)
endif
endif

# C library files installation (src/*.so -> $(CLIBDIR)/*.so)
# Pattern matches entire path structure from build to installation
$(CLIBDIR)/%.$(LIB_EXTENSION): src/%.$(LIB_EXTENSION)
	$(INSTALL_FILES)

# Command script installation (bin/*.lua -> $(BINDIR)/*)
$(BINDIR)/%: bin/%.lua
	$(INSTALL_FILES)
	@chmod +x $@

# Command installation target
install-commands: $(CMD_TARGETS)

# Lua library files installation (lua/*.lua -> $(LUALIBDIR)/*)
$(LUALIBDIR)/%: lua/%
	$(INSTALL_FILES)

# Lua library installation target
install-lualibs: $(LUALIBS)

# Main installation target - installs all discovered files
install: install-commands install-lualibs $(MAINLIB) $(MODULE_LIBS)
	@echo ""
	@echo "DEBUG: Install phase environment variables:"
	@echo "LUADIR: $(LUADIR)"
	@echo "LIBDIR: $(LIBDIR)"
	@echo "BINDIR: $(BINDIR)"
	@echo ""
	@echo "Installation complete"
	# Clean up build files in the source directory
	@$(MAKE) clean-objects

##
# Debug and utility targets
##
# Show all build variables - useful for debugging and verification
show-vars:
	@echo "=== External Variables ==="
	@echo "PACKAGE_NAME: $(PACKAGE_NAME)"
	@echo "LIB_EXTENSION: $(LIB_EXTENSION)"
	@echo "LUADIR: $(LUADIR)"
	@echo "LIBDIR: $(LIBDIR)"
	@echo "BINDIR: $(BINDIR)"
	@echo ""
	@echo "=== Input Files ==="
	@echo "CMD_SOURCES: $(CMD_SOURCES)"
	@echo "LUASRCS: $(LUASRCS)"
	@echo "MODULES: $(MODULES)"
	@echo ""
	@echo "=== Generated Targets ==="
	@echo "CMD_TARGETS: $(CMD_TARGETS)"
	@echo "LUALIBS: $(LUALIBS)"
	@echo "MAINLIB: $(MAINLIB)"
	@echo "MODULE_NAMES: $(MODULE_NAMES)"
	@echo "MODULE_TARGETS: $(MODULE_TARGETS)"
	@echo "MODULE_LIBS: $(MODULE_LIBS)"

# Clean target - remove all build artifacts
# Works independently without requiring any external variables
clean-objects:
	# Remove all libraries (.so/.dll) and object files
	find src \( -name "*.so" -o -name "*.dll" -o -name "*.o" \) -delete 2>/dev/null || true
	find lib \( -name "*.a" -o -name "*.o" \) -delete 2>/dev/null || true

clean:
	# Remove all coverage artifacts
	find src \( -name "*.gcda" -o -name "*.gcno" \) -delete 2>/dev/null || true
	find lib \( -name "*.gcda" -o -name "*.gcno" \) -delete 2>/dev/null || true
	# Clean up build files in the source directory
	@$(MAKE) clean-objects
