local Modux = require(game.ReplicatedStorage.Shared.Modux)

local DebugService = Modux.Service("DebugService")

function DebugService:Panic(Origin: string, Mensage: string)
    warn(`[PANIC - {Origin}] - {Mensage}.`)
end

return DebugService