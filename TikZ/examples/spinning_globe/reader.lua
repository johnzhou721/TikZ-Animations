-- reader.lua
local function register_tex_cmd(name, func, args, protected)
    name = "__jasper_" .. name .. ":" .. ("n"):rep(#args)
    local scanners = {}
    for _, arg in ipairs(args) do
        scanners[#scanners+1] = token['scan_' .. arg]
    end
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

local continents = {"africa","asia","europe","namer","samer"}
local suffixes   = {"-bdy.txt","-cil.txt","-riv.txt"}

cos,sin,rad = math.cos,math.sin,math.rad

local function sphere(lat, lon)
    lon = rad(lon)  -- λ: -180 to 180
    lat = rad(lat)  -- φ: -90 to 90
    return {
        cos(lat) * cos(lon),  -- x
        cos(lat) * sin(lon),  -- y
        sin(lat)              -- z
    }
end


local function view()
    local a = rad(token.get_macro("azimuth"))
    local e = rad(token.get_macro("elevation"))
    return {
        sin(a)*cos(e),
       -cos(a)*cos(e),
        sin(e)
    }
end

register_tex_cmd(
    'globe', function()
        for _, c in ipairs(continents) do
            for _, s in ipairs(suffixes) do
                local file = c .. "/" .. c .. s
                local seg, count, lastS = nil, 0, nil
                for line in io.lines(file) do
                    local id = line:match("^segment%s+(%d+)")
                    if id then
                        if seg and #seg > 1 then
                            tex.sprint("\\draw[line join=round,ultra thin] " .. table.concat(seg," -- ") .. ";\n")
                        end
                        seg, count, lastS = {}, 0, nil
                    else
                        local lon, lat = line:match("([%d%.%-]+)%s+([%d%.%-]+)")
                        if lon and lat then
                            count = count + 1
                            local S = sphere(lon,lat)
                            lastS = S  -- remember last point
                            local V = view(lon,lat)
                            if count % 50 == 1 and (S[1]*V[1] + S[2]*V[2] + S[3]*V[3] >= 0) then
                                table.insert(seg, string.format("(%.4f,%.4f,%.4f)", S[1],S[2],S[3]))
                            end
                        end
                    end
                end
                -- ensure last point is included
                if lastS and seg then
                    table.insert(seg, string.format("(%.4f,%.4f,%.4f)", lastS[1],lastS[2],lastS[3]))
                end
                if seg and #seg > 1 then
                    tex.sprint("\\draw[line join=round,ultra thin] " .. table.concat(seg," -- ") .. ";\n")
                end
            end
        end
    end,
    {}
)
