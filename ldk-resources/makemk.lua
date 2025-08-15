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

--- add a file to a group based on its prefix
--- @param group table the file group to add to
--- @param src string the source path of the file to add
--- @param name string the name of the file to add
--- @param ext string the extension of the file to add
local function group_by_prefix(group, src, name, ext)
    for gname, grp in pairs(group) do
        -- if the file prefix matches the group name
        if #gname < #name and name:sub(1, #gname) == gname then
            -- add the file to the group
            grp.srcs[#grp.srcs + 1] = src
            if ext == 'cpp' then
                grp.linker = '$(CXX)'
                if not grp.libs['-lstdc++'] then
                    grp.libs['-lstdc++'] = true
                    grp.libs[#grp.libs + 1] = '-lstdc++'
                end
            end
            return
        end
    end

    -- create a new group for the file
    local grp = {srcs = {src}, linker = '$(CC)', libs = {}}
    if ext == 'cpp' then
        grp.linker = '$(CXX)'
        grp.libs['-lstdc++'] = true
        grp.libs[#grp.libs + 1] = '-lstdc++'
    end
    group[name] = grp
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
    -- add the file to the directory info
    dirinfo.names[#dirinfo.names + 1] = name
    dirinfo.ext4name[name] = ext
    dirinfo.src4name[name] = pathname
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
                            dirinfo.ext4name[name])
        end
    end

    return dirs
end

--- create a target for the module as the Makefile fragment.
--- e.g.
---   foo_SRCS = src/foo1.c src/foo2.cpp
---   foo_OBJS = $(foo_SRCS:.cpp=.o)
---   foo_OBJS := $(foo_OBJS:.c=.o)
---   foo_LINK = $(CXX)
---   foo_LIBS = -lstdc++
---
--- @param dirname string the directory name
--- @param gname string the group name
--- @param group table the group information
--- @return table target the Makefile fragment for the module
local function make_target(dirname, gname, group)
    local module = dirname .. gname
    -- Convert path to target name (src/foo/bar -> foo_bar)
    local name = module:gsub('^src/', ''):gsub('/', '_')
    local lines = ([[
# target for @MODULE@
@NAME@_SRC = @SRCS@
@NAME@_OBJS = $(@NAME@_SRC:.c=.o)
@NAME@_OBJS := $(@NAME@_OBJS:.cpp=.o)
@NAME@_LINK = @LINKER@
@NAME@_LIBS = @LIBS@]]):gsub('@([^@]+)@', {
        MODULE = module,
        NAME = name,
        LINKER = group.linker,
        LIBS = concat(group.libs, ' '),
        SRCS = concat(group.srcs, ' ')
    })
    return {module = module, lines = lines}
end

--- create targets for each module in a specific directory
--- @param dirpath string the path to the directory
--- @return table a list of targets for the modules in the directory
local function make_targets(dirpath)
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
            local target = make_target(dirinfo.dirname, gname, group)
            targets[#targets + 1] = target
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

-- Write module definitions and build rules
file:write([[
#
# Module definitions and build rules
#
]])

-- Process src/ directory for shared library modules
local modules = {}
local src_targets = make_targets('src/')
for _, target in ipairs(src_targets) do
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
