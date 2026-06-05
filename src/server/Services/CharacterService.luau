local Players = game:GetService("Players")
local Modux = require(game.ReplicatedStorage.Shared.Modux)

local CharacterService = Modux.Service("CharacterService")

CharacterService:Import("PlayerService")

local PLAYERS_COLITION_GROUP = "PlayerGroup"

local DecendentsConnections = {}

local function DiconnectDecendentConnection(Player: Player)
    local FindConnection = DecendentsConnections[tostring(Player.UserId)]
    if not FindConnection then
        return
    end

    local sucess, response = pcall(function(...)
        FindConnection:Disconnect()
    end)

    if not sucess then
        warn(`[{script.Name} - DiconnectDecendentConnection] Error in init. Error_Mensager = {response}`)
        return
    end

    DecendentsConnections[tostring(Player.UserId)] = nil
end

local function SetCharacterCollisionGroup(Part: BasePart)
    if Part.CollisionGroup == PLAYERS_COLITION_GROUP then
        return
    end


    
    Part.CollisionGroup = PLAYERS_COLITION_GROUP
end

local function CreateDecendentsConnection(Character: Model)
    local PlayerUserId: string = tostring(Players:GetPlayerFromCharacter(Character).UserId)
    DecendentsConnections[PlayerUserId]  = Character.DescendantAdded:Connect(function(Part: Instance)
        if Part:IsA("BasePart") then
            SetCharacterCollisionGroup(Part)
        end
    end)
end

local function InitChangedCollitionGroup(Character)
    for _, Decentends in Character:GetDescendants() do
        if Decentends:IsA("BasePart") then
            SetCharacterCollisionGroup(Decentends)
        end
    end

    CreateDecendentsConnection(Character)
end

CharacterService:OnInit(function(self)
    if #self.PlayerService:GetAllCharacters() > 0 then
        for _, Character in self.PlayerService:GetAllCharacters() do
            InitChangedCollitionGroup(Character)
        end
    end

    self.PlayerService:OnCharacterAdded(function(Character, _)
        InitChangedCollitionGroup(Character)
    end)

    self.PlayerService.OnCharacterRemoved(function(Plr: Player)
        DiconnectDecendentConnection(Plr)
    end)
end)

CharacterService:OnStart(function(self)end)

return CharacterService