-- lua-tikz3dtools-register-tex-cmd.lua

local rtc = {}

-- https://tex.stackexchange.com/a/747040
--- Creates a TeX command that evaluates a Lua function
---
--- @param name string The name of the `\csname` to define
--- @param func function
--- @param args table<string> The TeX types of the function arguments
--- @param protected boolean|nil Define the command as `\protected`
--- @return nil
function rtc.register_tex_cmd(name, func, args, protected)
    -- The extended version of this function uses `N` and `w` where appropriate,
    -- but only using `n` is good enough for exposition purposes.
    name = "__lua_tikztdtools_" .. name .. ":" .. ("n"):rep(#args)

    -- Push the appropriate scanner functions onto the scanning stack.
    local scanners = {}
    for _, arg in ipairs(args) do
        scanners[#scanners+1] = token['scan_' .. arg]
    end

    -- An intermediate function that properly "scans" for its arguments
    -- in the TeX side.
    local scanning_func = function()
        local values = {}
        for _, scanner in ipairs(scanners) do
            values[#values+1] = scanner()
        end

        func(table.unpack(values))
    end

    local index = luatexbase.new_luafunction(name)
    lua.get_functions_table()[index] = scanning_func

    if protected then
        token.set_lua(name, index, "protected")
    else
        token.set_lua(name, index)
    end
end

return rtc