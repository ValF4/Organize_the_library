export type MapController = {
    SetMap: (Self: MapController, Map: string) -> (),
    SetDifficulty: (Self: MapController, Difficult: string) -> (),
    GetMap: (Self: MapController) -> string | nil,
    GetDifficulty: (Self: MapController) -> string | nil
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = ReplicatedStorage.Shared.Types
local MapConfigType = require(Types.MapConfigType)

local CurrentMapController = {} :: MapController
local MapConfig = {}

MapConfig.MapSelect = nil
MapConfig.Difficulty = nil

function CurrentMapController:SetMap(Map: string)
    MapConfig.MapSelect = Map
end

function CurrentMapController:SetDifficulty(Difficult: string)
    MapConfig.Difficult = Difficult
end

function CurrentMapController:GetMap()
    return MapConfig.MapSelect
end

function CurrentMapController:GetDifficulty()
    return MapConfig.Difficult
end

return CurrentMapController