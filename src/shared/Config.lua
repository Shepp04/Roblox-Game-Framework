--!strict
local Config = {}

-- // Type Defs
export type PlayerData = typeof(Config.PROFILE_TEMPLATE)
export type PlayerInfo = typeof(Config.INFO_TEMPLATE)

export type PlayerProfile = {
	Data: PlayerData,
	Info: PlayerInfo,
	Reconcile: (self: PlayerProfile) -> (),
	EndSession: (self: PlayerProfile) -> (),
	AddUserId: (self: PlayerProfile, userId: number) -> (),
	OnSessionEnd: RBXScriptSignal,
}

-- // Data Templates
Config.PROFILE_TEMPLATE = {
	Stats = {
		Cash = 0;
	};
	Analytics = {
		TotalLogins = 0;
		TotalPlaytime = 0;
		LastLeaveTime = nil;
	};
}

Config.INFO_TEMPLATE = {
	JoinTime = 0;
	Multipliers = {};
}

return Config