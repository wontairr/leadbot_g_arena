LeadBot.RespawnAllowed = true -- allows bots to respawn automatically when dead
LeadBot.PlayerColor = true -- disable this to get the default gmod style players
LeadBot.NoNavMesh = false -- disable the nav mesh check
LeadBot.TeamPlay = false -- don't hurt players on the bots team
LeadBot.LerpAim = true -- interpolate aim (smooth aim)
LeadBot.AFKBotOverride = false -- allows for gamemodes such as Dogfight which use IsBot() to pass real humans as bots
LeadBot.SuicideAFK = false -- kill the player when entering/exiting afk
LeadBot.Strategies = 1 -- how many strategies can the bot pick from

--[[ COMMANDS ]]--

concommand.Add("leadbot_add", function(ply, _, args) if IsValid(ply) and !ply:IsSuperAdmin() then return end local amount = 1 if tonumber(args[1]) then amount = tonumber(args[1]) end for i = 1, amount do timer.Simple(i * 0.1, function() LeadBot.AddBot() end) end end, nil, "Adds a LeadBot")
concommand.Add("leadbot_kick", function(ply, _, args) if !args[1] or IsValid(ply) and !ply:IsSuperAdmin() then return end if args[1] ~= "all" then for k, v in pairs(player.GetBots()) do if string.find(v:GetName(), args[1]) then v:Kick() return end end else for k, v in pairs(player.GetBots()) do v:Kick() end end end, nil, "Kicks LeadBots (all is avaliable!)")
CreateConVar("leadbot_strategy", "1", {FCVAR_ARCHIVE, FCVAR_NOTIFY}, "Enables the strategy system for newly created bots.")
CreateConVar("leadbot_names", "", {FCVAR_ARCHIVE, FCVAR_NOTIFY}, "Bot names, seperated by commas.")
CreateConVar("leadbot_models", "", {FCVAR_ARCHIVE, FCVAR_NOTIFY}, "Bot models, seperated by commas.")
CreateConVar("leadbot_name_prefix", "", {FCVAR_ARCHIVE, FCVAR_NOTIFY}, "Bot name prefix")
CreateConVar("leadbot_fov", "0", {FCVAR_ARCHIVE, FCVAR_NOTIFY}, "LeadBot FOV\nSet to 0 to use the preset FOV.")
CreateConVar("leadbot_gameover", "0", {FCVAR_ARCHIVE, FCVAR_PROTECTED}, "thing for G-Arena")

--[[ FUNCTIONS ]]--

local name_Default = {
    alyx = "Alyx Vance",
    kleiner = "Isaac Kleiner",
    breen = "Dr. Wallace Breen",
    gman = "The G-Man",
    odessa = "Odessa Cubbage",
    eli = "Eli Vance",
    monk = "Father Grigori",
    mossman = "Judith Mossman",
    mossmanarctic = "Judith Mossman",
    barney = "Barney Calhoun",


    dod_american = "American Soldier",
    dod_german = "German Soldier",

    css_swat = "GIGN",
    css_leet = "Elite Crew",
    css_arctic = "Artic Avengers",
    css_urban = "SEAL Team Six",
    css_riot = "GSG-9",
    css_gasmask = "SAS",
    css_phoenix = "Phoenix Connexion",
    css_guerilla = "Guerilla Warfare",

    hostage01 = "Art",
    hostage02 = "Sandro",
    hostage03 = "Vance",
    hostage04 = "Cohrt",

    police = "Civil Protection",
    policefem = "Civil Protection",

    chell = "Chell",

    combine = "Combine Soldier",
    combineprison = "Combine Prison Guard",
    combineelite = "Elite Combine Soldier",
    stripped = "Stripped Combine Soldier",

    zombie = "Zombie",
    zombiefast = "Fast Zombie",
    zombine = "Zombine",
    corpse = "Corpse",
    charple = "Charple",
    skeleton = "Skeleton",

    male01 = "Van",
    male02 = "Ted",
    male03 = "Joe",
    male04 = "Eric",
    male05 = "Art",
    male06 = "Sandro",
    male07 = "Mike",
    male08 = "Vance",
    male09 = "Erdin",
    male10 = "Van",
    male11 = "Ted",
    male12 = "Joe",
    male13 = "Eric",
    male14 = "Art",
    male15 = "Sandro",
    male16 = "Mike",
    male17 = "Vance",
    male18 = "Erdin",
    female01 = "Joey",
    female02 = "Kanisha",
    female03 = "Kim",
    female04 = "Chau",
    female05 = "Naomi",
    female06 = "Lakeetra",
    female07 = "Joey",
    female08 = "Kanisha",
    female09 = "Kim",
    female10 = "Chau",
    female11 = "Naomi",
    female12 = "Lakeetra",

    medic01 = "Van",
    medic02 = "Ted",
    medic03 = "Joe",
    medic04 = "Eric",
    medic05 = "Art",
    medic06 = "Sandro",
    medic07 = "Mike",
    medic08 = "Vance",
    medic09 = "Erdin",
    medic10 = "Joey",
    medic11 = "Kanisha",
    medic12 = "Kim",
    medic13 = "Chau",
    medic14 = "Naomi",
    medic15 = "Lakeetra",

    refugee01 = "Ted",
    refugee02 = "Eric",
    refugee03 = "Sandro",
    refugee04 = "Vance",
}

function LeadBot.AddBot()
    if !FindMetaTable("NextBot").GetFOV then
        ErrorNoHalt("You must be using the dev version of Garry's mod!\nhttps://wiki.facepunch.com/gmod/Dev_Branch\n")
        return
    end

    if !navmesh.IsLoaded() and !LeadBot.NoNavMesh then
        ErrorNoHalt("There is no navmesh! Generate one using \"nav_generate\"!\n")
        return
    end

    if player.GetCount() == game.MaxPlayers() then
        MsgN("[LeadBot] Player limit reached!")
        return
    end

    local original_name
    local generated = "Leadbot #" .. #player.GetBots() + 1
    local model = ""
    local color = Vector(-1, -1, -1)
    local weaponcolor = Vector(0.30, 1.80, 2.10)
    local strategy = 0

    if GetConVar("leadbot_names"):GetString() ~= "" then
        generated = table.Random(string.Split(GetConVar("leadbot_names"):GetString(), ","))
    elseif GetConVar("leadbot_models"):GetString() == "" then
        local name, _ = table.Random(player_manager.AllValidModels())
        local translate = player_manager.TranslateToPlayerModelName(name)
        name = translate

        for _, ply in pairs(player.GetBots()) do
            if ply.OriginalName == name or string.lower(ply:Nick()) == name or name_Default[name] and ply:Nick() == name_Default[name] then
                name = ""
            end
        end

        if name == "" then
            local i = 0
            while name == "" do
                i = i + 1
                local str = player_manager.TranslateToPlayerModelName(table.Random(player_manager.AllValidModels()))
                for _, ply in pairs(player.GetBots()) do
                    if ply.OriginalName == str or string.lower(ply:Nick()) == str or name_Default[str] and ply:Nick() == name_Default[str] then
                        str = ""
                    end
                end

                if str == "" and i < #player_manager.AllValidModels() then continue end
                name = str
            end
        end

        original_name = name
        model = name
        name = string.lower(name)
        name = name_Default[name] or name

        local name_Generated = string.Split(name, "/")
        name_Generated = name_Generated[#name_Generated]
        name_Generated = string.Split(name_Generated, " ")

        for i, namestr in pairs(name_Generated) do
            name_Generated[i] = string.upper(string.sub(namestr, 1, 1)) .. string.sub(namestr, 2)
        end

        name_Generated = table.concat(name_Generated, " ")
        generated = name_Generated
    end

    if LeadBot.PlayerColor == "default" then
        generated = "Kleiner"
    end

    generated = GetConVar("leadbot_name_prefix"):GetString() .. generated

    local name = LeadBot.Prefix .. generated
    local bot = player.CreateNextBot(name)

    if !IsValid(bot) then
        MsgN("[LeadBot] Unable to create bot!")
        return
    end

    if GetConVar("leadbot_strategy"):GetBool() then
        strategy = math.random(0, LeadBot.Strategies)
    end

    if LeadBot.PlayerColor ~= "default" then
        if model == "" then
            if GetConVar("leadbot_models"):GetString() ~= "" then
                model = table.Random(string.Split(GetConVar("leadbot_models"):GetString(), ","))
            else
                model = player_manager.TranslateToPlayerModelName(table.Random(player_manager.AllValidModels()))
            end
        end

        if color == Vector(-1, -1, -1) then
            local botcolor = ColorRand()
            local botweaponcolor = ColorRand()
            color = Vector(botcolor.r / 255, botcolor.g / 255, botcolor.b / 255)
            weaponcolor = Vector(botweaponcolor.r / 255, botweaponcolor.g / 255, botweaponcolor.b / 255)
        end
    else
        model = "kleiner"
        color = Vector(0.24, 0.34, 0.41)
    end

    bot.LeadBot_Config = {model, color, weaponcolor, strategy}

    -- for legacy purposes, will be removed soon when gamemodes are updated
    bot.BotStrategy = strategy
    bot.OriginalName = original_name
    bot.ControllerBot = ents.Create("leadbot_navigator")
    bot.ControllerBot:Spawn()
    bot.ControllerBot:SetOwner(bot)
    bot.LeadBot = true
    LeadBot.AddBotOverride(bot)
    LeadBot.AddBotControllerOverride(bot, bot.ControllerBot)
    MsgN("[LeadBot] Bot " .. name .. " with strategy " .. bot.BotStrategy .. " added!")
end

--[[ DEFAULT DM AI ]]--

function LeadBot.AddBotOverride(bot)
end

function LeadBot.AddBotControllerOverride(bot, controller)
end

function LeadBot.PlayerSpawn(bot)
end

function LeadBot.Think()
    for _, bot in pairs(player.GetBots()) do
        if bot:IsLBot() then
            if !GetConVar("leadbot_gameover"):GetBool() and LeadBot.RespawnAllowed and bot.NextSpawnTime and !bot:Alive() and bot.NextSpawnTime < CurTime() then
                bot:Spawn()
                return
            end

            local wep = bot:GetActiveWeapon()
            if IsValid(wep) then
                local ammoty = wep:GetPrimaryAmmoType() or wep.Primary.Ammo
                bot:SetAmmo(999, ammoty)
            end
        end
    end
end

function LeadBot.PostPlayerDeath(bot)
end

function LeadBot.PlayerHurt(ply, bot, hp, dmg)
    if bot:IsPlayer() then

        local controller = ply:GetController()

        controller.LookAtTime = CurTime() + 2
        controller.LookAt = ((bot:GetPos() + VectorRand() * 128) - ply:GetPos()):Angle()
    end
end

function LeadBot.StartCommand(bot, cmd)
    local buttons = IN_SPEED
    local botWeapon = bot:GetActiveWeapon()
    local controller = bot.ControllerBot
    local target = controller.Target

    if !IsValid(controller) or GetConVar("leadbot_gameover"):GetBool() then return end

    if LeadBot.NoSprint then
        buttons = 0
    end

    if IsValid(botWeapon) and (botWeapon:Clip1() == 0 or !IsValid(target) and botWeapon:Clip1() <= botWeapon:GetMaxClip1() / 2) then
        buttons = buttons + IN_RELOAD
    end

    if IsValid(target) and math.random(2) == 1 then
        buttons = buttons + IN_ATTACK
    end

    if bot:GetMoveType() == MOVETYPE_LADDER then
        local pos = controller.goalPos
        local ang = ((pos + bot:GetCurrentViewOffset()) - bot:GetShootPos()):Angle()

        if pos.z > controller:GetPos().z then
            controller.LookAt = Angle(-30, ang.y, 0)
        else
            controller.LookAt = Angle(30, ang.y, 0)
        end

        controller.LookAtTime = CurTime() + 0.1
        controller.NextJump = -1
        buttons = buttons + IN_FORWARD
    end

    if controller.NextDuck > CurTime() then
        buttons = buttons + IN_DUCK
    elseif controller.NextJump == 0 then
        controller.NextJump = CurTime() + 1
        buttons = buttons + IN_JUMP
    end

    if !bot:IsOnGround() and controller.NextJump > CurTime() then
        buttons = buttons + IN_DUCK
    end

    bot:SelectWeapon((IsValid(controller.Target) and controller.Target:GetPos():DistToSqr(controller:GetPos()) < 129000 and "weapon_shotgun") or "weapon_smg1")
    cmd:ClearButtons()
    cmd:ClearMovement()
    cmd:SetButtons(buttons)
end

function LeadBot.PlayerMove(bot, cmd, mv)
    local controller = bot.ControllerBot

    if !IsValid(controller) then
        bot.ControllerBot = ents.Create("leadbot_navigator")
        bot.ControllerBot:Spawn()
        bot.ControllerBot:SetOwner(bot)
        controller = bot.ControllerBot
    end

    --[[local min, max = controller:GetModelBounds()
    debugoverlay.Box(controller:GetPos(), min, max, 0.1, Color(255, 0, 0, 0), true)]]

    -- force a recompute
    if controller.PosGen and controller.P and controller.TPos ~= controller.PosGen then
        controller.TPos = controller.PosGen
        controller.P:Compute(controller, controller.PosGen)
    end

    if controller:GetPos() ~= bot:GetPos() then
        controller:SetPos(bot:GetPos())
    end

    if controller:GetAngles() ~= bot:EyeAngles() then
        controller:SetAngles(bot:EyeAngles())
    end

    mv:SetForwardSpeed(1200)

    if (bot.NextSpawnTime and bot.NextSpawnTime + 1 > CurTime()) or !IsValid(controller.Target) or controller.ForgetTarget < CurTime() or controller.Target:Health() < 1 then
        controller.Target = nil
    end

    if !IsValid(controller.Target) then
        for _, ply in ipairs(player.GetAll()) do
            if ply ~= bot and ((ply:IsPlayer() and (!LeadBot.TeamPlay or (LeadBot.TeamPlay and (ply:Team() ~= bot:Team())))) or ply:IsNPC()) and ply:GetPos():DistToSqr(bot:GetPos()) < 2250000 then
                --[[local targetpos = ply:EyePos() - Vector(0, 0, 10)
                local trace = util.TraceLine({
                    start = bot:GetShootPos(),
                    endpos = targetpos,
                    filter = function(ent) return ent == ply end
                })]]

                if ply:Alive() and controller:CanSee(ply) then
                    controller.Target = ply
                    controller.ForgetTarget = CurTime() + 2
                end
            end
        end
    elseif controller.ForgetTarget < CurTime() and controller:CanSee(controller.Target) then
        controller.ForgetTarget = CurTime() + 2
    end

    local dt = util.QuickTrace(bot:EyePos(), bot:GetForward() * 45, bot)

    if IsValid(dt.Entity) and dt.Entity:GetClass() == "prop_door_rotating" then
        dt.Entity:Fire("OpenAwayFrom", bot, 0)
    end

    if !IsValid(controller.Target) and (!controller.PosGen or bot:GetPos():DistToSqr(controller.PosGen) < 1000 or controller.LastSegmented < CurTime()) then
        -- find a random spot on the map, and in 10 seconds do it again!
        controller.PosGen = controller:FindSpot("random", {radius = 12500})
        controller.LastSegmented = CurTime() + 10
    elseif IsValid(controller.Target) then
        -- move to our target
        local distance = controller.Target:GetPos():DistToSqr(bot:GetPos())
        controller.PosGen = controller.Target:GetPos()

        -- back up if the target is really close
        -- TODO: find a random spot rather than trying to back up into what could just be a wall
        -- something like controller.PosGen = controller:FindSpot("random", {pos = bot:GetPos() - bot:GetForward() * 350, radius = 1000})?
        if distance <= 90000 then
            mv:SetForwardSpeed(-1200)
        end
    end

    -- movement also has a similar issue, but it's more severe...
    if !controller.P then
        return
    end

    local segments = controller.P:GetAllSegments()

    if !segments then return end

    local cur_segment = controller.cur_segment
    local curgoal = segments[cur_segment]

    -- got nowhere to go, why keep moving?
    if !curgoal or GetConVar("leadbot_gameover"):GetBool() then
        mv:SetForwardSpeed(0)
        return
    end

    -- think every step of the way!
    if segments[cur_segment + 1] and Vector(bot:GetPos().x, bot:GetPos().y, 0):DistToSqr(Vector(curgoal.pos.x, curgoal.pos.y)) < 100 then
        controller.cur_segment = controller.cur_segment + 1
        curgoal = segments[controller.cur_segment]
    end

    local goalpos = curgoal.pos

    -- waaay too slow during gamplay
    --[[if bot:GetVelocity():Length2DSqr() <= 225 and controller.NextCenter == 0 and controller.NextCenter < CurTime() then
        controller.NextCenter = CurTime() + math.Rand(0.5, 0.65)
    end

    if controller.NextCenter ~= 0 and controller.NextCenter < CurTime() then
        if bot:GetVelocity():Length2DSqr() <= 225 then
            controller.strafeAngle = ((controller.strafeAngle == 1 and 2) or 1)
        end

        controller.NextCenter = 0
    end]]

    if bot:GetVelocity():Length2DSqr() <= 225 then
        if controller.NextCenter < CurTime() then
            controller.strafeAngle = ((controller.strafeAngle == 1 and 2) or 1)
            controller.NextCenter = CurTime() + math.Rand(0.3, 0.65)
        elseif controller.nextStuckJump < CurTime() then
            if !bot:Crouching() then
                controller.NextJump = 0
            end
            controller.nextStuckJump = CurTime() + math.Rand(1, 2)
        end
    end

    if controller.NextCenter > CurTime() then
        if controller.strafeAngle == 1 then
            mv:SetSideSpeed(1500)
        elseif controller.strafeAngle == 2 then
            mv:SetSideSpeed(-1500)
        else
            mv:SetForwardSpeed(-1500)
        end
    end

    -- jump
    if controller.NextJump ~= 0 and curgoal.type > 1 and controller.NextJump < CurTime() then
        controller.NextJump = 0
    end

    -- duck
    if curgoal.area:GetAttributes() == NAV_MESH_CROUCH then
        controller.NextDuck = CurTime() + 0.1
    end

    controller.goalPos = goalpos

    if GetConVar("developer"):GetBool() then
        controller.P:Draw()
    end

    -- eyesight
    local lerp = FrameTime() * math.random(8, 10)
    local lerpc = FrameTime() * 8

    if !LeadBot.LerpAim then
        lerp = 1
        lerpc = 1
    end

    local mva = ((goalpos + bot:GetCurrentViewOffset()) - bot:GetShootPos()):Angle()

    mv:SetMoveAngles(mva)

    if IsValid(controller.Target) then
        bot:SetEyeAngles(LerpAngle(lerp, bot:EyeAngles(), (controller.Target:EyePos() - bot:GetShootPos()):Angle()))
        return
    else
        if controller.LookAtTime > CurTime() then
            local ang = LerpAngle(lerpc, bot:EyeAngles(), controller.LookAt)
            bot:SetEyeAngles(Angle(ang.p, ang.y, 0))
        else
            local ang = LerpAngle(lerpc, bot:EyeAngles(), mva)
            bot:SetEyeAngles(Angle(ang.p, ang.y, 0))
        end
    end
end

--[[ HOOKS ]]--

hook.Add("PlayerDisconnected", "LeadBot_Disconnect", function(bot)
    if IsValid(bot.ControllerBot) then
        bot.ControllerBot:Remove()
    end
end)

hook.Add("SetupMove", "LeadBot_Control", function(bot, mv, cmd)
    if bot:IsLBot() then
        LeadBot.PlayerMove(bot, cmd, mv)
    end
end)

hook.Add("StartCommand", "LeadBot_Control", function(bot, cmd)
    if bot:IsLBot() then
        LeadBot.StartCommand(bot, cmd)
    end
end)

hook.Add("PostPlayerDeath", "LeadBot_Death", function(bot)
    if bot:IsLBot() then
        LeadBot.PostPlayerDeath(bot)
    end
end)

hook.Add("EntityTakeDamage", "LeadBot_Hurt", function(ply, dmgi)
    local bot = dmgi:GetAttacker()
    local hp = ply:Health()
    local dmg = dmgi:GetDamage()

    if IsValid(ply) and ply:IsPlayer() and ply:IsLBot() then
        LeadBot.PlayerHurt(ply, bot, hp, dmg)
    end
end)

hook.Add("Think", "LeadBot_Think", function()
    LeadBot.Think()
end)

hook.Add("PlayerSpawn", "LeadBot_Spawn", function(bot)
    if bot:IsLBot() then
        LeadBot.PlayerSpawn(bot)
    end
end)

--[[ META ]]--

local player_meta = FindMetaTable("Player")
local oldInfo = player_meta.GetInfo

function player_meta.IsLBot(self, realbotsonly)
    if realbotsonly == true then
        return self.LeadBot and self:IsBot() or false
    end

    return self.LeadBot or false
end

function player_meta.LBGetStrategy(self)
    if self.LeadBot_Config then
        return self.LeadBot_Config[4]
    else
        return 0
    end
end

function player_meta.LBGetModel(self)
    if self.LeadBot_Config then
        return self.LeadBot_Config[1]
    else
        return "kleiner"
    end
end

function player_meta.LBGetColor(self, weapon)
    if self.LeadBot_Config then
        if weapon == true then
            return self.LeadBot_Config[3]
        else
            return self.LeadBot_Config[2]
        end
    else
        return Vector(0, 0, 0)
    end
end

function player_meta.GetInfo(self, convar)
    if self:IsBot() and self:IsLBot() then
        if convar == "cl_playermodel" then
            return self:LBGetModel() --self.LeadBot_Config[1]
        elseif convar == "cl_playercolor" then
            return self:LBGetColor() --self.LeadBot_Config[2]
        elseif convar == "cl_weaponcolor" then
            return self:LBGetColor(true) --self.LeadBot_Config[3]
        else
            return ""
        end
    else
        return oldInfo(self, convar)
    end
end

function player_meta.GetController(self)
    if self:IsLBot() then
        return self.ControllerBot
    end
end