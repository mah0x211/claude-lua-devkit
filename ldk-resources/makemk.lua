--
-- Copyright (C) 2025 Masatoshi Fukunaga
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
-- THE SOFTWARE.
--
-- This script generates a Makefile fragment for building C/C++ source files
-- in the src/ directory, grouping them by their prefixes.
--
-- PREFIX GROUPING RULES:
-- - Files are sorted by name length (shortest first)
-- - Longer filenames are checked against existing shorter names as prefixes
-- - If a prefix match is found, files are grouped into the same module
--
-- EXAMPLES:
--   src/foo.c, src/foo_bar.c, src/foo_baz.c
--   → Grouped into 'foo' module with all three files
--
--   src/bar.c, src/baz.c
--   → Separate modules: 'bar' and 'baz'
--
-- The script also handles both C and C++ files, ensuring that the correct
-- compiler and flags are used based on the file type.
--
local concat = table.concat
local sort = table.sort
local format = string.format
local stderr = io.stderr
stderr:setvbuf('no') -- disable buffering

-- Create mk/ directory if it doesn't exist
local function mkdir_p(path)
    local cmd = format('mkdir -p "%s"', path)
    local res = os.execute(cmd)
    -- Lua 5.1 returns 0 on success, Lua 5.2+ returns true
    if res ~= true and res ~= 0 then
        error(format('Failed to create directory: %s', path))
    end
end

--- merge two tables, avoiding duplicates
--- @param src table the source table
--- @param dest table? the destination table, if nil to create a new table
--- @return table dest
local function merge_tables(src, dest)
    dest = dest or {}
    for _, v in ipairs(src) do
        if not dest[v] then
            dest[v] = true
            dest[#dest + 1] = v
        end
    end
    return dest
end

--- merge flags from the source table into the destination table
--- @param src table the source table
--- @param dest table? the destination table, if nil to create a new table
--- @param ... string the keys to merge from the source table
--- @return table dest
local function merge_flags(src, dest, ...)
    dest = dest or {}
    for _, k in ipairs({...}) do
        dest[k] = merge_tables(src[k] or {}, dest[k])
    end
    return dest
end

--- add a file to a group based on its prefix
--- @param group table the file group to add to
--- @param src string the source path of the file to add
--- @param name string the name of the file to add
--- @param ext string the extension of the file to add
--- @param flags table flags directives for the file
local function group_by_prefix(group, src, name, ext, flags)
    for gname, grp in pairs(group) do
        -- if the file prefix matches the group name
        if #gname < #name and name:sub(1, #gname) == gname then
            -- add the file to the group
            grp.srcs[#grp.srcs + 1] = src
            -- merge compiler flags for the source file
            grp.flags4src[src] = merge_flags(flags, grp.flags4src[src],
                                             'cppflags', 'cflags', 'cxxflags')

            -- Set linker and library flags for C++ files
            if ext == 'cpp' then
                grp.linker = 'cxx'
                merge_tables({'-lstdc++'}, grp.ldflags)
            end
            -- merge linker and library flags
            merge_flags(flags, grp, 'ldflags', 'reflibs')
            return
        end
    end

    -- create a new group for the file
    local grp = {
        srcs = {src},
        linker = ext == 'cpp' and 'cxx' or 'cc',
        ldflags = ext == 'cpp' and {'-lstdc++'} or {},
        reflibs = {},
        flags4src = {[src] = {}}
    }
    -- Add compiler flags
    merge_flags(flags, grp.flags4src[src], 'cppflags', 'cflags', 'cxxflags')
    -- Add library flags
    merge_flags(flags, grp, 'ldflags', 'reflibs')
    group[name] = grp
end

--- parse source file directives like //@ldflags:, //@cflags:, //@cppflags:, //@cxxflags:, //@reflibs:
--- @param filepath string the path to the source file
--- @return table directives parsed flags
local function parse_directives(filepath)
    local directives = {}
    local file = io.open(filepath, "r")
    if not file then return directives end

    local in_multiline_comment = false
    local lineno = 0
    for line in file:lines() do
        local is_comment = in_multiline_comment
        lineno = lineno + 1

        -- If we're in a multi-line comment
        if in_multiline_comment then
            -- Check for multi-line comment end */
            if line:find('%*/') then
                in_multiline_comment = false
                -- remove ending marker
                line = line:gsub('%*+/', '')
            end
        elseif line:find('^%s*/%*') then
            -- multi-line comment start
            in_multiline_comment = true
        elseif line:find('^%s*//') then
            -- single-line comment
            is_comment = true
        elseif line:find('^%s*[^#]') then
            -- Stop at first non-comment, non-preprocessor line (actual code)
            break
        elseif line:find('^%s*#') and line:find('^%s*#include') then
            -- Stop at #include
            break
        end

        -- If this is a comment line, check for directives
        if is_comment then
            local lowerl = line:lower()
            for _, fname in ipairs({
                'cppflags', -- C/C++ preprocessor flags (e.g., -DDEBUG, -Iinclude)
                'cflags', -- C compiler flags (e.g., -Wall, -Werror, -std=c11)
                'cxxflags', -- C++ compiler flags (e.g., -std=c++20)
                'ldflags', -- Linker flags (e.g., -L/lib -lm)
                'reflibs' -- References to static libraries in lib/ directory (e.g., string util/memory)
            }) do
                local match = lowerl:match('%s*[@]' .. fname .. ':%s*(.+)$')
                if match then
                    if directives[fname] then
                        -- Duplicate directive found
                        error(format(
                                  'Duplicate directive %q found in file %s:%d',
                                  line:match('@.*$'), filepath, lineno))
                    end
                    local value = line:match(':%s*(.+)$')
                    if value then
                        local flags = directives[fname] or {}
                        directives[fname] = flags
                        if fname == 'reflibs' or fname == 'ldflags' then
                            -- Split by whitespace and add to the list
                            for v in value:gmatch('%S+') do
                                flags[#flags + 1] = v
                            end
                        else
                            flags[#flags + 1] = value
                        end
                    end
                end
            end
        end
    end
    file:close()

    return directives
end

--- get the directory information
--- @param dirs table a table to store directory information
--- @param pathname string the path to the file
local function get_dirinfo(dirs, pathname)
    -- split the file to dir, name
    local dirname, filename = pathname:match('^(.-)([^/]+)$')
    -- split the filename to name, ext
    local name, ext = filename:match('^([^%.]+)%.([^%.]+)$')
    local dirinfo = dirs[dirname]

    if not dirinfo then
        dirinfo = {
            dirname = dirname,
            names = {},
            ext4name = {},
            src4name = {},
            flags4name = {},
            groups = {}
        }
        dirs[dirname] = dirinfo
        dirs[#dirs + 1] = dirinfo
    end

    -- check for duplicate filenames
    if dirinfo.ext4name[name] then
        error(format(
                  'Cannot have the same filename %s.(%s|%s) in the same directory %s',
                  name, ext, dirinfo.ext4name[name], dirname))
    end

    -- Parse directives from source file
    local directives = parse_directives(pathname)

    -- add the file to the directory info
    dirinfo.names[#dirinfo.names + 1] = name
    dirinfo.ext4name[name] = ext
    dirinfo.src4name[name] = pathname
    dirinfo.flags4name[name] = directives
end

--- get the list of directories and files in src/
--- @param dirpath string the path to the directory to search
--- @return table a list of directories with their files
local function get_dirinfos(dirpath)
    local dirs = {}
    local command = format(
                        [[find %s -type f \( -name %s \) 2>/dev/null || true]],
                        dirpath, concat({'*.c', '*.cpp'}, ' -o -name '))

    for pathname in io.popen(command):lines() do
        -- process each file path
        get_dirinfo(dirs, pathname)
    end

    -- sort the directories by name
    sort(dirs, function(a, b) return a.dirname < b.dirname end)
    -- group files by prefix
    for _, dirinfo in ipairs(dirs) do
        -- sort the names
        sort(dirinfo.names)
        for _, name in ipairs(dirinfo.names) do
            group_by_prefix(dirinfo.groups, dirinfo.src4name[name], name,
                            dirinfo.ext4name[name], dirinfo.flags4name[name])
        end
    end

    return dirs
end

--- create a target for the module as the Makefile fragment.
--- @param dirname string the directory name
--- @param gname string the group name
--- @param group table the group information
--- @param is_static boolean? whether the target is a static library
--- @param reflibs table? a list of static library targets to link against
--- @return table target the Makefile fragment for the module
local function make_target(dirname, gname, group, is_static, reflibs)
    local target = {
        module = dirname .. gname,
        linker = group.linker,
        ldflags = merge_tables(group.ldflags)
    }
    local name = target.module:gsub('^[^%w_]+', ''):gsub('/', '_')
    -- common template for all targets
    local template = [[
# target for @@MODULE@@
@@NAME@@_SRC := @@SRCS@@
@@NAME@@_LINKER = $(@@LINKER@@)
@@NAME@@_LDFLAGS = @@LDFLAGS@@
@@NAME@@_OBJS := $(@@NAME@@_SRC:.c=.o)
@@NAME@@_OBJS := $(@@NAME@@_OBJS:.cpp=.o)
]]
    -- Generate @@EACH_OBJFLAGS@@ line
    local objflags = {}
    for _, src in ipairs(group.srcs) do
        local obj = src:gsub('%.c$', '.o'):gsub('%.cpp$', '.o')
        for fname, flags in pairs(group.flags4src[src]) do
            if #flags > 0 then
                objflags[#objflags + 1] =
                    format('%s_%s = %s', obj, fname:upper(), concat(flags, ' '))
            end
        end
    end
    if #objflags > 0 then
        template = template .. [[
# Set compiler flags for each object file
@@EACH_OBJFLAGS@@
]]
    end

    if is_static == true then
        -- Static library build rules
        template = template .. [[
# Build rule for static @@MODULE@@
@@NAME@@_AR = $(AR)
@@NAME@@_ARFLAGS = rcs
@@MODULE@@.a: $(@@NAME@@_OBJS)
	@mkdir -p $(@D)
	$(@@NAME@@_AR) $(@@NAME@@_ARFLAGS) $@ $^
 ]]

        target.lines = template:gsub('@@([^@]+)@@', {
            MODULE = target.module,
            NAME = name,
            SRCS = concat(group.srcs, ' '),
            LINKER = target.linker:upper(),
            LDFLAGS = concat(target.ldflags, ' '),
            EACH_OBJFLAGS = concat(objflags, '\n')
        })
        return target
    end

    -- Dynamic library build rules
    template = template .. [[
# Build rule for dynamic @@MODULE@@
@@MODULE@@.$(LIB_EXTENSION): $(@@NAME@@_OBJS) @@BUILD_REFLIBS@@
	@mkdir -p $(@D)
	$(@@NAME@@_LINKER) -o $@ $^ $(LDFLAGS) $(PLATFORM_LDFLAGS) $(@@NAME@@_LDFLAGS) $(COVFLAGS) $(SANITIZERFLAGS)
]]

    -- Link to static libraries in lib/ directory
    local build_reflibs = {}
    for _, libname in ipairs(group.reflibs) do
        libname = 'lib/' .. libname
        local reflib = reflibs[libname]
        if reflib then
            if reflib.linker == 'cxx' then
                -- if library contains C++ code, use C++ linker
                target.linker = reflib.linker
            end
            -- merge ldflags
            target.ldflags = merge_tables(reflib.ldflags, target.ldflags)
        end
        target.ldflags[#target.ldflags + 1] = libname .. '.a'
        build_reflibs[#build_reflibs + 1] = libname .. '.a'
    end

    target.lines = template:gsub('@@([^@]+)@@', {
        MODULE = target.module,
        NAME = name,
        SRCS = concat(group.srcs, ' '),
        LINKER = target.linker:upper(),
        LDFLAGS = concat(target.ldflags, ' '),
        EACH_OBJFLAGS = concat(objflags, '\n'),
        BUILD_REFLIBS = concat(build_reflibs, ' ')
    })
    return target
end

--- create targets for each module in a specific directory
--- @param dirpath string the path to the directory
--- @param is_static boolean? whether the target is a static library
--- @param reflibs table? a list of static library targets to link against
--- @return table targets a list of target for the modules in the directory
local function make_targets(dirpath, is_static, reflibs)
    if dirpath:find('^[^%w_]') then
        error(format('Target directory location %q must not start with ' ..
                         'a non-alphanumeric and non-underscore character',
                     dirpath))
    end
    local dirinfos = get_dirinfos(dirpath)
    local targets = {}
    for _, dirinfo in ipairs(dirinfos) do
        -- create a target for each group
        for gname, group in pairs(dirinfo.groups) do
            local target = make_target(dirinfo.dirname, gname, group, is_static,
                                       reflibs)
            targets[#targets + 1] = target
            targets[target.module] = target
        end
    end

    return targets
end

local function printf(...)
    -- print formatted output to stdout
    stderr:write(format(...), '\n')
end

printf(string.rep('#', 80))
printf('Generating mk/modules.mk...')

mkdir_p('mk')
printf('Opening mk/modules.mk for writing...')
local file, err = io.open('mk/modules.mk', 'w')
if not file then
    error(format('Failed to open mk/modules.mk for writing: %s', err))
end

-- Write header
file:write([[
# This file is generated by makemk.lua
# Do not edit this file directly.
# To regenerate this file, run `lua makemk.lua` from the project root.
# Generated on: ]] .. os.date('%Y-%m-%d %H:%M:%S'), '\n\n')

-- Write default variable definitions
file:write([[
#
# Default variable definitions
#
AR ?= ar

# C++ compiler configuration
# If CXX is not properly set, derive it from CC to inherit all SDK and platform
# settings. This ensures C++ compilation uses the same environment settings as
# C compilation.
ifndef CXX
CXX = $(subst gcc,g++,$(subst clang,clang++,$(CC)))
else ifeq ($(CXX),c++)
# If CXX is just the basic 'c++', replace it with a derived version from CC
CXX = $(subst gcc,g++,$(subst clang,clang++,$(CC)))
endif
]])

-- Write module definitions and build rules
file:write([[
#
# Generic compilation rules
#
%.o: %.c
	$(CC) $(CPPFLAGS) $($@_CPPFLAGS) $(CFLAGS) $($@_CFLAGS) $(PLATFORM_CFLAGS) $(WARNINGS) $(COVFLAGS) $(SANITIZERFLAGS) -o $@ -c $<

%.o: %.cpp
	$(CXX) $(CPPFLAGS) $($@_CPPFLAGS) $(CXXFLAGS) $($@_CXXFLAGS) $(PLATFORM_CXXFLAGS) $(WARNINGS) $(COVFLAGS) $(SANITIZERFLAGS) -o $@ -c $<

#
# Module definitions and build rules
#
]])

-- Process lib/ directory for static library modules
local reflibs = make_targets('lib/', true)
for _, target in ipairs(reflibs) do
    printf('static library %q target to be generated: %s_*', target.module,
           target.module)
    file:write(target.lines, '\n\n')
    target.lines = nil
end

-- Process src/ directory for shared library modules
local modules = {}
for _, target in ipairs(make_targets('src/', false, reflibs)) do
    modules[#modules + 1] = target.module
    printf('module %q target to be generated: %s_*', target.module,
           target.module)
    file:write(target.lines, '\n\n')
end
-- Write module lists
file:write(format('MODULES = %s', concat(modules, ' ')), '\n')

file:close()
printf('mk/modules.mk generated successfully.')
printf(string.rep('#', 80))
