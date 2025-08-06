--!strict
local Config = {}

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