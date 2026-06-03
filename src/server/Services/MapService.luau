-- Services
local CollectionService = game:GetService("CollectionService")
local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

-- Instances
local Shared = ReplicatedStorage:WaitForChild("Shared") 
local Types = Shared:WaitForChild("Types")
local Enums = Shared:WaitForChild("Enums")

local Maps = ReplicatedStorage:WaitForChild("Maps")

--Modules
local CurrentMapConfig = require(ReplicatedStorage.Shared.Lists.CurrentMapConfig)
local Modux         = require(game.ReplicatedStorage.Shared.Modux)
local MapConfigType = require(Types.MapConfigType)

--Enums
local DifficultEnum = require(Enums.DifficultEnum)

-- Modux
local MapService = Modux.Service("MapService")

--Imports
MapService:Import("DebugService")

local CURRENT_MAP: MapConfigType.MapConfig = { -- Estas informações viram do lobby para o jogo
    MapSelect = "Tutorial",
    Difficult = DifficultEnum.Easy
}

local CheckingHasMapSelect = function(): boolean
    if not CurrentMapConfig then
        return false
    end

    if not CurrentMapConfig:GetMap() or not CurrentMapConfig:GetDifficulty() then
        return false
    end

    return true
end

local function SetMapSelected(Map: MapConfigType.MapConfig)
    if not Map then
        MapService.DebugService:Panic(script.Name, "Map Select is nil")
        return
    end

    local hasMapSelect = CheckingHasMapSelect()
    if hasMapSelect then
        MapService.DebugService:Panic(script.Name, "Exist map selected")
        return
    end

    CurrentMapConfig:SetMap(Map.MapSelect)
    CurrentMapConfig:SetDifficulty(Map.Difficult)
end

local function LoadMap() : Folder | nil
    if not CheckingHasMapSelect() then
        MapService.DebugService:Panic(script.Name, "Not has Map selected")
        return
    end

    local CurrentMap = CurrentMapConfig:GetMap()
    if not CurrentMap then
        MapService.DebugService:Panic(script.Name, "Map selected is nil")
        return
    end

    local MapFolder: Folder = Maps:FindFirstChild(CurrentMap)
    if not MapFolder then
        MapService.DebugService:Panic(script.Name, `Map: {CurrentMap} not find in Maps Folder.`)
        return
    end

    local CloneMap = MapFolder:Clone()

    local success, response = pcall(function(...)
        ContentProvider:PreloadAsync(CloneMap:GetChildren())
    end)

    if not success then
        MapService.DebugService:Panic(script.Name, `Error in load {CurrentMap}. Error: {response}`)
        CloneMap:Destroy()
        return nil
    end

    return CloneMap
end

local function InitMap(Map: Folder)
    if not Map then 
        MapService.DebugService:Panic(script.Name, `Map folder is nil, error in load the Map.`)
        return
    end

    Map.Name = "CurrentMap"
    Map.Parent = Workspace
    CollectionService:AddTag(Map, "Map")
end

MapService:OnStart(function(self)
    SetMapSelected(CURRENT_MAP)
    local Map = LoadMap()
    InitMap(Map)
end)

return MapService
