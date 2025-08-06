--!strict
-- // Type Defs
export type NametagType = "Default" | "Modern" | "None"
export type NametagTypeInfo = {
    Gui: BillboardGui?,
    PlayerNamePrefix: string,
    PlayerNameSuffix: string,
}

type NametagConfig = {
    DefaultType: NametagType,
    Types: { [NametagType]: NametagTypeInfo },
}

-- // Assets
local GuiFolder = script:WaitForChild("Assets")

-- // Configuration
local NametagConfig = {} :: NametagConfig

-- // CUSTOMISE // --
NametagConfig.DefaultType = "Modern" :: NametagType
NametagConfig.Types = {
    Default = {
        Gui = GuiFolder:WaitForChild("Default") :: BillboardGui,
        PlayerNamePrefix = "",
        PlayerNameSuffix = "",
    },
    Modern = {
        Gui = GuiFolder:WaitForChild("Modern") :: BillboardGui,
        PlayerNamePrefix = "@",
        PlayerNameSuffix = "",
    },
    None = {
        Gui = nil, -- No GUI for "None" type
        PlayerNamePrefix = "",
        PlayerNameSuffix = "",
    }
}

return NametagConfig