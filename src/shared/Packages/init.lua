--!strict

-- // Paths
local rawPackages = {
    Sounds = require(script.Sounds),
    UI = require(script.UI),
    Remotes = require(script.Remotes),
    Debounce = require(script.Debounce),
    ReplicatedData = require(script.ReplicatedData),
    Collectables = require(script.Collectables),
}

local Packages = setmetatable({}, {
    __index = function(_, key)
        local package = rawPackages[key]
        if not package then
            error("Package '" .. tostring(key) .. "' does not exist.")
        end
        return package
    end,

    __newindex = function(_, key, value)
        error("Cannot add new packages. Use the existing ones: " .. table.concat(table.keys(rawPackages), ", "))
    end,
})

return Packages