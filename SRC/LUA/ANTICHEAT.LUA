-- ANTICHEAT.LUA
-- Code by LeonardoTheMutant, Re & nikoberry
--
-- A collection of anti-cheat algorithms



-- Hi,
-- Just wanted to say, if you are a cheater - fuck you.
-- Sincerely,
-- Leo



enum(
	"LOVEYOURSELF",
	"KYS_KIS",
	"KYS_AUTOMAP",
	"KYS_CVAR"
)

--"Kick Yourself"
COM_AddCommand("kys", function(p, id)
	local msg = {
		"Kicked itself",
		"Automap usage",
		"Usage of cheat CVAR(s)"
	}

	id = tonumber(id) or KYS_KIS
	if (id < 1) or (id > #msg) then return end

	COM_BufInsertText(server, string.format("kick %d %s", #p, msg[id]))
end)



--
-- AIMBOT
--
local PLAYER_RADIUS = mobjinfo[MT_PLAYER].radius / 16
local function predictMobjPos(mo, tics)
	local ray = P_SpawnMobj(mo.x, mo.y, mo.z, MT_RAY)
	ray.momx = mo.momx
	ray.momy = mo.momy
	ray.momz = mo.momz
	ray.flags = ray.flags & ~(MF_NOGRAVITY|MF_NOCLIPHEIGHT|MF_NOCLIP)

	for i = 0, tics do
		P_XYMovement(ray)
		P_ZMovement(ray)
	end

	return ray
end
addHook("PlayerSpawn", function(p)
	p.startangle = p.realmo.angle
end)
addHook("PlayerThink", function(p)
	if not (valid(p) and valid(p.mo)) then return end
	for plr in players.iterate do
		if (valid(plr) and valid(plr.mo) and (plr ~= p)) then
			--
			-- 1st check (basic)
			--
			if (p.mo.angle == R_PointToAngle2(p.mo.x, p.mo.y, plr.mo.x, plr.mo.y)) and (p.mo.angle ~= p.startangle) then
				CONS_Printf(server, string.format("\x85!!! %s has attempted to use aimbot !!!", p.name))
				MM.KillPlayer(p.mo, true, true)
				MM.TryEndgame()
			end

			--
			-- 2nd check (basic with movement prediction)
			--
			local target = predictMobjPos(plr.mo, p.cmd.latency)
			if (p.mo.angle == R_PointToAngle2(p.mo.x, p.mo.y, target.x, target.y)) and (p.mo.angle ~= p.startangle) then
				CONS_Printf(server, string.format("\x85!!! %s has attempted to use aimbot !!!", p.name))
				MM.KillPlayer(p.mo, true, true)
				MM.TryEndgame()
			end

			--
			-- 3rd & 4th checks (advanced, but only warns)
			--
			local angle = R_PointToAngle2(p.mo.x, p.mo.y, plr.mo.x, plr.mo.y)
			--Right point (from our perspective)
			local pointAx, pointAy, angleA
			--Left point
			local pointBx, pointBy, angleB

			if (AngleInRange(angle, ANGLE_315, ANGLE_135)) then
				--target at North-East
				--bottom-right
				pointAx = plr.mo.x + PLAYER_RADIUS
				pointAy = plr.mo.y - PLAYER_RADIUS
				--top-left
				pointBx = plr.mo.x - PLAYER_RADIUS
				pointBy = plr.mo.y + PLAYER_RADIUS
			elseif (AngleInRange(angle, ANGLE_45, ANGLE_225)) then
				--target at North-West
				--top-right
				pointAx = plr.mo.x + PLAYER_RADIUS
				pointAy = plr.mo.y + PLAYER_RADIUS
				--bottom-left
				pointBx = plr.mo.x - PLAYER_RADIUS
				pointBy = plr.mo.y - PLAYER_RADIUS
			elseif (AngleInRange(angle, ANGLE_135, ANGLE_315)) then
				--target at South-West
				--top-left
				pointAx = plr.mo.x - PLAYER_RADIUS
				pointAy = plr.mo.y + PLAYER_RADIUS
				--bottom-right
				pointBx = plr.mo.x + PLAYER_RADIUS
				pointBy = plr.mo.y - PLAYER_RADIUS
			elseif (AngleInRange(angle, ANGLE_225, ANGLE_45)) then
				--target at South-East
				--bottom-left
				pointAx = plr.mo.x - PLAYER_RADIUS
				pointAy = plr.mo.y - PLAYER_RADIUS
				--top-right
				pointBx = plr.mo.x + PLAYER_RADIUS
				pointBy = plr.mo.y + PLAYER_RADIUS
			end

			angleA = R_PointToAngle2(p.mo.x, p.mo.y, pointAx, pointAy)
			angleB = R_PointToAngle2(p.mo.x, p.mo.y, pointBx, pointBy)

			--Better nametag display
			--if (AngleInRange(p.mo.angle, angleA, angleB)) then
			--	CONS_Printf(p, plr.name) --replace with v.drawString()
			--end

			--
			-- 3rd check (without additional angle checks)
			--
			local dist = FixedInt(R_PointToDist2(p.mo.x, p.mo.y, plr.mo.x, plr.mo.y))
			if (p.cmd.buttons & BT_ATTACK) and AngleInRange(p.mo.angle, angleA, angleB) and (dist > MELEERANGE) and (isdedicatedserver) then
				local pmo = p.mo
				local plrmo = plr.mo
				local fmt = "!!! %s is firing at %s at near origin - distance: %d, hunter momentum: <%d; %d>, target momentum: <%d; %d>) !!!"
				CONS_Printf(server, string.format(fmt, p.name, plr.name, dist, FixedInt(pmo.momx), FixedInt(pmo.momy), FixedInt(plrmo.momx), FixedInt(plrmo.momy)))
			end

			--
			-- 4th check (with additional angle checks)
			--
			local DIVISOR = 16 --I may not know the correct name for this, but this is the number you divide by

			local dist = FixedInt(R_PointToDist2(p.mo.x, p.mo.y, plr.mo.x, plr.mo.y))
			if (p.cmd.buttons & BT_ATTACK) and AngleInRange(p.mo.angle, angleA - (AngleDiff(angleA, angle)/DIVISOR), angleB + (AngleDiff(angle, angleB)/DIVISOR)) and (dist > MELEERANGE)
			and (isdedicatedserver) then
				local pmo = p.mo
				local plrmo = plr.mo
				local fmt = "!!! %s is firing at %s with a good precision - distance: %d, hunter momentum: <%d; %d>, target momentum: <%d; %d>) !!!"
				CONS_Printf(server, string.format(fmt, p.name, plr.name, dist, FixedInt(pmo.momx), FixedInt(pmo.momy), FixedInt(plrmo.momx), FixedInt(plrmo.momy)))
			end
		end
	end
end)



--
-- AUTOMAP
--

local cv_automap1 = CV_FindVar("automapoutsidedevmode")
local cv_automap2 = CV_FindVar("tsourdt3rd_debug_automapanywhere")
local cv_automap3 = CV_FindVar("forceautomap")
addHook("KeyDown", function(keyevent)
	if (gametype == GT_LTMMURDERMYSTERY) and (keyevent.num == 9)
	and ((cv_automap1 and cv_automap1.value) or (cv_automap2 and cv_automap2.value) or (cv_automap3 and cv_automap3.value))
	then
		COM_BufInsertText(consoleplayer, "QUIT")
		COM_BufInsertText(consoleplayer, string.format("KYS %d", KYS_AUTOMAP))
	end
end)



--
-- CHEAT CVAR
--

local function Blind(str)
	MM.hud.game.flash.translucency = 10
	MM.hud.game.flash.duration = 1
	MM.hud.game.flash.color = 31
	if not (leveltime % TICRATE) then
		chatprintf(consoleplayer, str)
	end
end

local cv_fullbright = CV_FindVar("fullbrite")
local cv_secbright = CV_FindVar("r_secbright")
local cv_camclipping = CV_FindVar("cam_clipping")
local cv_renderhitbox = CV_FindVar("renderhitbox")
addHook("ThinkFrame", function()
	if (gametype ~= GT_LTMMURDERMYSTERY) or (leveltime < TICRATE) or (leveltime % 4) then return end
	if (cv_fullbright) and (cv_fullbright.value) then
		COM_BufInsertText(consoleplayer, "QUIT")
		COM_BufInsertText(consoleplayer, string.format("KYS %d", KYS_CVAR))
	end

	if (cv_renderhitbox) and (cv_renderhitbox.value) then
		COM_BufInsertText(consoleplayer, "QUIT")
		COM_BufInsertText(consoleplayer, string.format("KYS %d", KYS_CVAR))
	end

	if (cv_camclipping) and (cv_camclipping.value == 0) then
		Blind("Please set \"cam_clipping\" to a value other than 0")
	end

	if (cv_forceautomap) and (cv_forceautomap.value) then
		Blind("Please disable \"forceautomap\" in your console")
	end

	if (cv_secbright) and (cv_secbright.value) then
		Blind("Please set \"r_secbright\" to 0")
	end
end)



--
-- ILLEGAL STATES
--

addHook("PlayerSpawn", function(p)
	p.oldname = p.name
end)

local cv_abilities = CV_FindVar("mm_abilities")
local cv_restrictskinchange = CV_FindVar("restrictskinchange")
addHook("PlayerThink", function(p)
	if (gametype ~= GT_LTMMURDERMYSTERY) or (leveltime < TICRATE) then return end
	if (cv_abilities) and not (cv_abilities.value) and (p.mo)
	and ((p.mo.state == S_PLAY_SPINDASH) or (p.mo.state == S_PLAY_DASH) or (p.mo.state == S_PLAY_FLY)
	or (p.mo.state == S_PLAY_GLIDE) or (p.mo.state == S_PLAY_FLOAT) or (p.mo.state == S_PLAY_FLOAT_RUN)
	or (p.mo.state == S_PLAY_TWINSPIN) or (p.mo.state == S_PLAY_MELEE_FINISH)) then
		CONS_Printf(server, string.format("\x85!!! %s has attempted to perform an illegal move !!!", p.name))
		MM.KillPlayer(p.mo, true, true)
		MM.TryEndgame()
	end

	if (p.name ~= p.oldname) and (leveltime > 105) and (p.jointime > 105) then
		if (p.mm.role == ROLE_DEAD) and (MM.PlayerCount() > 2) and not (leveltime % 4) then
			MM.PunishPlayer(p, "Do not rename when dead!")
		else
			p.oldname = p.name
		end
	end
end)
