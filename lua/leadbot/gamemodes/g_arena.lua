--[[GAMEMODE CONFIGURATION START]]--

LeadBot.RespawnAllowed = true
LeadBot.SetModel = true
LeadBot.Gamemode = "g_arena"
LeadBot.TeamPlay = false
LeadBot.LerpAim = true
LeadBot.NoSprint = true
LeadBot.NoFlashlight = true

if GetConVar("garena_enableteams"):GetBool() then
    print("teams enabled")
    LeadBot.TeamPlay = true
else
    LeadBot.TeamPlay = false
end

--[[GAMEMODE CONFIGURATION END]]--