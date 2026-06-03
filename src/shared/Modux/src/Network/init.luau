--!strict
local BugReporterService = game:GetService("BugReporterService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.Shared.Modux.Types)
local lync = require(script.lync)

type Packet<T> = lync.Packet<T>
type DataTemplate = Types.DataTemplate
type DataKeyPayload = Types.DataKeyPayload

local Network = {}
setmetatable(Network, { __index = lync })
Network.__index = Network

-- Codec compartilhado para as keys individuais (reutilizado em Packages e Types)
Network.Packages = {
	-- Pacote completo: enviado no login ou quando múltiplas keys mudam de uma vez
	Data = Network.packet(
		"Data",
		Network.struct({
			Cash = Network.int(0, 4294967295),
			MusicVolume = Network.int(0, 1),
			SoundVolume = Network.int(0, 1),
			SoundEnabled = Network.bool,
			MusicEnabled = Network.bool,
		})
	) :: Packet<DataTemplate>,

	-- Pacote de key única: 1 byte de tag + N bytes do valor
	-- Payload: { key = "Cash", Cash = 1000 }
	DataKey = Network.packet(
		"DataKey",
		Network.tagged("key", {
			Cash = Network.struct({ Cash = Network.int(0, 4294967295) }),
			MusicVolume = Network.struct({ MusicVolume = Network.int(0, 1) }),
			SoundVolume = Network.struct({ SoundVolume = Network.int(0, 1) }),
			SoundEnabled = Network.struct({ SoundEnabled = Network.bool }),
			MusicEnabled = Network.struct({ MusicEnabled = Network.bool }),
		})
	) :: Packet<DataKeyPayload>,

	ZoneNotification = Network.packet(
		"ZoneNotification",
		Network.struct({
			Message = Network.string(20),
		})
	),

	SecondsCycle = Network.packet(
		"SecondsCycle",
		Network.struct({
			Message = Network.int(0, 420),
		})
	),
	DayCycle = Network.packet(
		"DayCycle",
		Network.struct({
			Message = Network.int(0, 10000),
		})
	),

	VitalKey = Network.packet(
		"VitalKey",
		Network.tagged("key", {
			Armor = Network.struct({ value = Network.int(0, 100) }),
			Health = Network.struct({ value = Network.int(0, 100) }),
			Hunger = Network.struct({ value = Network.int(0, 100) }),
			Stamina = Network.struct({ value = Network.int(0, 100) }),
			Oxygen = Network.struct({ value = Network.int(0, 300) }),
			MaxOxygen = Network.struct({ value = Network.int(0, 300) }),
		})
	),
}

Network.start()

return Network
