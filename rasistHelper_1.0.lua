script_name = "rasistHelper"
script_description("Suhanov RasistArrest Helper")
script_version_number(1)
script_version("v1")
script_authors("Progst")

local inicfg = require 'inicfg'
local http = require 'socket.http'
local dlstatus = require('moonloader').download_status
require "lib.moonloader"
require "lib.sampfuncs"

local UPDATE_THREAD = nil
local VERSION = "1.0"
local ACTUAL = VERSION
local download_id = nil

local DS_MSGBOX = 0
local DS_INPUT = 1
local DS_LIST = 2
local DS_PASS = 3
local DS_TABLIST = 4
local DS_TABHEAD = 5

local dlgMAIN	= 300
local dlgCMDS	= 301
local dlgSETLIST = 302
local dlgSETUP = 303
local dlgEXTRA = 304
local dlgSCROPT = 305
local dlgUPDATE = 333

local config = {
	main = {
		nick = "",
		fname = "",
		lname = "",
		rang = "",
		sex = false
	},
	func = {
		dub = false,
		cuff = false,
		follow = false,
		tocar = false
	},
	other = {
		timestamp = false,
		updating = false,
		version = ""
	}
}

local scriptLoadingIntro = false
local scriptENTERDATA = false
local scriptTEMPSETID = 0
local scriptAUTODUB = false
local scriptCUFFID = -1
local scriptARRID = -1
local scriptPUTPLID = -1
local scriptSEARCHID = -1
local scriptSHOWMEDOCS = false
local scriptGOTOID, scriptGOTOMODE = -1, false

function download_handler(id, status, p1, p2)
  if stop_downloading then
    stop_downloading = false
    download_id = nil
    printStyledString('Loading canceled', 2000, 4)
    return false -- �������� ��������
  end
  if status == dlstatus.STATUS_DOWNLOADINGDATA then
    printStyledString(string.format('Loaded %d from %d.', p1, p2), 2000, 4)
  elseif status == dlstatus.STATUS_ENDDOWNLOADDATA then
    printStyledString('Loading done', 2000, 4)
		download_id = nil
  end
end

function update()
	tickCount = 0
	scr_width, scr_height = getScreenResolution()
	local font_flag = require('moonloader').font_flag
	local my_font = renderCreateFont('Verdana', 12, font_flag.BOLD + font_flag.SHADOW)
	local nickf, nickname, nickid
	while true do
		wait(1)
		if config.other.timestamp then
			nickf, nickid = sampGetPlayerIdByCharHandle(playerPed)
			if nickf then nickname = sampGetPlayerNickname(nickid)
			else nickid = -1; nickname = ""
			end
			renderFontDrawText(my_font, "{CCFFFFFF}" .. nickname .. "[" .. nickid .. "]\n[ " .. os.date("%d.%m.%Y | %H:%M:%S") .. " ]", scr_width - #nickname * 15, scr_height - 45, 0xFFFFFFFF)
		end
	end
end

function main()
	wait(2000)
	if not isSampLoaded() then return end
	if not isSampfuncsLoaded() then return end
	while not sampIsLocalPlayerSpawned() do wait(2500) end

	loadConfigs()
	if #config.other.version == 0 then config.other.version = VERSION
	elseif config.other.version ~= VERSION then goto end_script
	end
	saveConfigs()

	if scriptLoadingIntro then loadingScreen() end
	-- Register Commands -- -- --------------------
	sampRegisterChatCommand("v", cmdMenu)
	sampRegisterChatCommand("vasya", cmdMenu)
	while scriptENTERDATA == true do onDialogRespone(); wait(1) end
	sampRegisterChatCommand("z", cmdShowme)
  sampRegisterChatCommand("x", cmdDocs)
	sampRegisterChatCommand("got", cmdGoto)
	sampRegisterChatCommand("putpl", cmdPutInCar)
	sampRegisterChatCommand("search", cmdSearchp)
	sampRegisterChatCommand("cuff", cmdCuff)
	sampRegisterChatCommand("ids", cmdFinder)
	sampRegisterChatCommand("arr", cmdArrest); sampRegisterChatCommand("arrest", cmdArrest);
	sampRegisterChatCommand("tim", cmdTime)

  -- Script Code Start
	UPDATE_THREAD = lua_thread.create(update)

	while true do
		wait(0)
		while isGamePaused() do wait(100) end
		-- -- System Updates -- -- ------------------
		onDialogRespone();

		-- -- Script Features -- -- ----------------
		local chat = sampGetChatString(99)
		if config.func.dub then
			if string.find(chat, "�� ��������") ~= nil and string.find(chat, "15 ������") then
				sampSendChat("/me ���" .. (config.main.sex and "��" or "����").. " ���� �������� �� ����������")
				local aid, anick = getPlaLine(chat)
				if config.func.cuff then
					sampSendChat("/me ������ ��������� ���� ������" .. (config.main.sex and "" or "�") .. "��������� � �����")
					wait(800)
					sampSendChat("/cuff " .. aid)
				end
				wait(1000)
			end
		end

		if string.find(chat, config.main.fname) ~= nil and string.find(chat, "�o���") then
			local aid, anick = getPlaLine(chat)
			if string.find(chat, "�a ��o�") then scriptGOTOMODE = true else scriptGOTOMODE = false end
			scriptGOTOID = aid
			wait(1300)
			sampSendChat("����")
			wait(100)
		end

		if string.find(chat, config.main.fname) ~= nil and string.find(chat, "���� ���") then
			scriptGOTOID = -1
			wait(1300)
			sampSendChat("����")
			wait(100)
		end

		if string.find(chat, config.main.fname) ~= nil and string.find(chat, "��a��:") then
			-- local aid, anick = getPlaLine(chat)
			local tosay = string.sub( chat, string.find(chat, "��a��:") + 6 )
			wait(500)
			sampSendChat(tosay)
			wait(100)
		end

		if string.find(chat, config.main.fname) ~= nil and string.find(chat, "�p����:") then
			-- local aid, anick = getPlaLine(chat)
			local tosay = string.sub( chat, string.find(chat, "�p����:") + 7 )
			wait(500)
			sampSendChat("/s " .. tosay)
			wait(100)
		end

		if scriptGOTOID ~= -1 then
			local rr, targetPed = sampGetCharHandleBySampPlayerId(scriptGOTOID)
			if not rr then
				scriptGOTOID = -1;
				setGameKeyState(GOFORWARD_GOBACK, 0)
			else
				local CENTER_X, CENTER_Y, CENTER_Z = getCharCoordinates(playerPed)
				local TARGET_X, TARGET_Y, TARGET_Z = getCharCoordinates(targetPed)
				if scriptGOTOMODE == true then
					if getDistPla(CENTER_X, CENTER_Y, CENTER_Z, TARGET_X, TARGET_Y, TARGET_Z) > 2 then
						local ANGLE = getAnglePla(CENTER_X, CENTER_Y, TARGET_X, TARGET_Y)
						setCharHeading(playerPed, ANGLE)
						setGameKeyState(GOFORWARD_GOBACK, 255)
					end
				else
					local dist = getDistPla(CENTER_X, CENTER_Y, CENTER_Z, TARGET_X, TARGET_Y, TARGET_Z)
					if dist > 1 and dist < 10 then
						setCharHeading(playerPed, getCharHeading(targetPed))
						setGameKeyState(GOFORWARD_GOBACK, 255)
					end
				end
			end
		end

		if scriptCUFFID ~= -1 then
			sampSendChat("/me ������ ��������� ���� ������" .. (config.main.sex == true and "" or "�") .. " ��������� � �����")
			wait(1100)
			sampSendChat("/me ����" .. (config.main.sex == true and "" or "�") .. " ��������� �� ����������")
			wait(800)
			sampSendChat("/cuff " .. scriptCUFFID)
			scriptCUFFID = -1
			wait(200)
		end

		if scriptARRID ~= -1 then
			sampSendChat("/me �������" .. (config.main.sex == true and "" or "�") .. " �������� ���������")
			wait(800)
			sampSendChat("/me ��" .. (config.main.sex == true and "��" or "���") .. " ������ � ���������� � �������" .. (config.main.sex == true and "" or "�") .. " �������� � �������")
			wait(1200)
			sampSendChat("/arrest " .. scriptARRID)
			scriptARRID = -1
			wait(200)
		end

		if scriptPUTPLID ~= -1 then
			sampSendChat("/me ������" .. (config.main.sex == true and "" or "�") .. " ����� ������������ ����������")
			wait(1200)
			sampSendChat("/me ��������" .. (config.main.sex == true and "" or "�") .. " ���������� � ����������")
			wait(1000)
			sampSendChat("/putpl " .. scriptPUTPLID)
			scriptPUTPLID = -1
			wait(200)
		end

		if scriptSEARCHID ~= -1 then
			sampSendChat("/me ������" .. (config.main.sex == true and "" or "�") .. " ��������� ��������")
			wait(1600)
			sampSendChat("/me �����" .. (config.main.sex == true and "" or "�") .. " ��������� �������� �� ����")
			wait(1800)
			sampSendChat("/me ��������" .. (config.main.sex == true and "" or "�") .. " �������������� �� ��������")
			wait(1200)
			sampSendChat("/anim 16")
			wait(1800)
			sampSendChat("/me ��������" .. (config.main.sex == true and "" or "�") .. " �������������� �� �����")
		  wait(1300)
			sampSendChat("/anim 14")
			wait(2000)
			sampSendChat("/me ����" .. (config.main.sex == true and "" or "�") .. " �������� � �����" .. (config.main.sex == true and "" or "�") .. " �� � ������")
			wait(1300)
			sampSendChat("/search " .. scriptSEARCHID)
			scriptSEARCHID = -1
			wait(200)
		end

		if config.func.dub == true then
			if scriptAUTODUB and getCurrentCharWeapon(playerPed) ~= 3 then
				sampSendChat("/me �������" .. (config.main.sex == true and "" or "�") .. " ������� �� ����")
				scriptAUTODUB = false
				wait(200)
			elseif not scriptAUTODUB and getCurrentCharWeapon(playerPed) == 3 then
				sampSendChat("/me ����" .. (config.main.sex == true and "" or "�") .. " ������� � �����")
				scriptAUTODUB = true
				wait(200)
			end
		end

		if scriptSHOWMEDOCS == true then
			-- fixNick
			sampSendChat("������� ������� �����. ��� ��������� ��������� ��� " .. config.main.fname .. " " .. config.main.lname .. ".")
			wait(1200)
			sampSendChat("/me ���������" .. (config.main.sex == true and "" or "�") .. " ������ ���������� ���")
			wait(1200)
			sampSendChat("������ ������� ���������� �������������, �������������� ���� ��������.")
			wait(200)
			scriptSHOWMEDOCS = false
		end
	end
	::end_script::
end

-- -- Functions -- -- ---------------------------
function loadingScreen()
	for i = 1, 29 do
		local lt = ""
		if i % 2 ~= 0 then
			local top = math.floor(i / 5)
			for j = 1, top do lt = lt .. " ]" end
			for j = 1, 5 - top do lt = lt .. "~l~ ]" end
		else
			for j = 1, 5 do lt = lt .. "~l~ ]" end
		end
		printStyledString(lt, 1000, 4)
		wait(100)
	end
	addOneOffSound(0, 0, 0, 1147)
	wait(2000)
end

function loadConfigs()
	config = inicfg.load(config, "rasistHelper")
	if (#config.main.nick == 0 or
			#config.main.fname == 0 or
			#config.main.lname == 0 or
			#config.main.rang == 0) then scriptENTERDATA = true
	else scriptENTERDATA = false end
	if config.other.updating == true then
		config.other.updating = false
		showDlg(dlgUPDATE)
		saveConfigs()
	end
end

function saveConfigs()
	inicfg.save(config, "rasistHelper")
	if (#config.main.nick == 0 or
			#config.main.fname == 0 or
			#config.main.lname == 0 or
			#config.main.rang == 0) then scriptENTERDATA = true
	else scriptENTERDATA = false end
end

function tryToUpdateScript(onlyVersion)
	if onlyVersion == true then
		local url = 'https://raw.githubusercontent.com/devProgst/devProgst.github.io/master/version.txt'
		local file_path = getWorkingDirectory() .. '/downloads/file.txt'
		download_id = downloadUrlToFile(url, file_path, download_handler)

		local downloadTries = 0
		while download_id ~= nil do
			wait(300)
			downloadTries = downloadTries + 1; if downloadTries > 10 then download_stop = true break end
		end

		local fv = io.open(file_path, "r")
		if (fv) then
		  local tempver = fv:read()
			if string.find(tempver, "!SCRIPT_VERSION_PREFIX! v. ") then
				local sssss, eeeee = string.find(tempver, "v. ")
				ACTUAL = string.sub(tempver, sssss + 3)
			else ACTUAL = VERSION
			end
			fv:close()
		end
	else
		config.other.updating = true
		saveConfigs()
		wait(500)

		local url = 'https://raw.githubusercontent.com/devProgst/devProgst.github.io/master/rasistHelper.lua'
		local file_path = getWorkingDirectory() .. '/rasistHelper_' .. ACTUAL .. '.lua'
		download_id = downloadUrlToFile(url, file_path, download_handler)

		local downloadTries = 0
		while download_id ~= nil do
			wait(300)
			downloadTries = downloadTries + 1; if downloadTries > 10 then break end
		end
	end
end

-- -- Commands -- -- ---------------------------------
function cmdMenu(param)
	showDlg(dlgMAIN)
end

function cmdGoto(param)
	if not sampIsPlayerConnected(tonumber(param)) then scriptGOTOID = -1; return end
	scriptGOTOID = tonumber(param)
end

function cmdCuff(param)
	if not config.func.cuff then sampSendChat("/cuff " .. param) return end
	if not sampIsPlayerConnected(tonumber(param)) then scriptCUFFID = -1; return end
	scriptCUFFID = tonumber(param)
end

function cmdArrest(param)
	if not sampIsPlayerConnected(tonumber(param)) then sampSendChat("/cuff " .. param); scriptARRID = -1; return end
	scriptARRID = tonumber(param)
end

function cmdPutInCar(param)
	if not sampIsPlayerConnected(tonumber(param)) then sampSendChat("/putpl " .. param); scriptPUTPLID = -1; return end
	scriptPUTPLID = tonumber(param)
end

function cmdSearchp(param)
	if not sampIsPlayerConnected(tonumber(param)) then sampSendChat("/search " .. param); scriptSEARCHID = -1; return end
	scriptSEARCHID = tonumber(param)
end

function cmdShowme(param)
	scriptSHOWMEDOCS = true
end

-- -- Dialog Response and Showing -- -- --------------
function showDlg(dialogid)
	local dvalid, dcap, dcon, dbut1, dbut2, dtyp = true, "", "", "", "", "", ""
	if(dialogid == dlgMAIN) then
		if (scriptENTERDATA == true) then return showDlg(dlgSETLIST) end
		dcap = "{00BFFF}������� ���� ��������� �������"; dbut1 = "�������"; dbut2 = "�������"; dtyp = DS_LIST
		dcon = dcon .. "1. ������ ������\n2. ��������� ���������\n3. �������������� ���������\n4. ��������� �������\n{CCCCCC}5. ����������"
	elseif (dialogid == dlgCMDS) then
		dcap = "{00BFFF}������ ������"; dbut1 = "�����"; dbut2 = "�������"; dtyp = DS_MSGBOX
		dcon = dcon .. "{DD9955}/v (/vasya) {FFFFFF}- ������� ���� ���������\n"
		dcon = dcon .. "{DD9955}/z {FFFFFF}- �������� ���� ��������� (�������������)\n"
		dcon = dcon .. "{DD9955}/x {FFFFFF}- ��������� �������� ���������\n"
		dcon = dcon .. "{DD9955}/c {FFFFFF}- ����� ��������� �� �����������\n"
		dcon = dcon .. "{DD9955}/arr {FFFFFF}- �������� ������ � ������\n"
		dcon = dcon .. "{DD9955}/ids {FFFFFF}- ������������ ������ � ���� ���������\n"
		dcon = dcon .. "{DD9955}/tim {FFFFFF}- ���������� �� ����\n"
	elseif (dialogid == dlgSETLIST) then
		dcap = "{00BFFF}��������� ���������"; dbut1 = "��������"; dbut2 = "�����"; dtyp = DS_TABHEAD
		dcon = dcon .. "��������\t��������\n\
			1. ��� ������\t" .. (#config.main.nick == 0 and "{DD2A2A}�� ������" or "{84DD2A}" .. config.main.nick  ) .. "\n\
			2. ���\t" .. (#config.main.fname == 0 and "{DD2A2A}�� �������" or "{84DD2A}" .. config.main.fname  ) .. "\n\
			3. �������\t" .. (#config.main.lname == 0 and "{DD2A2A}�� �������" or "{84DD2A}" .. config.main.lname  ) .. "\n\
			4. ���������\t" .. (#config.main.rang == 0 and "{DD2A2A}�� �������" or "{84DD2A}" .. config.main.rang  ) .. "\n\
			5. ���\t" .. (config.main.sex == false and "�������" or "�������"  ) .. "\n"
	elseif (dialogid == dlgSETUP) then
		dcap = "{00BFFF}��������� ���������"; dbut1 = "����"; dbut2 = "������"; dtyp = DS_INPUT
		if (scriptTEMPSETID == 0) then
			dcon = dcon .. "{FFFFFF}������� {F0BD48}��� ������ {FFFFFF} ��� �������� ���� �����\n������, ����� ������� ������� ���.\n\n������� ��� ������:"
		elseif (scriptTEMPSETID == 1) then
			dcon = dcon .. "{FFFFFF}������� {F0BD48}��� {FFFFFF} ������ ������.\n�����, ����� ��� ��������������� ������ ����� �������� ����.\n\n������� ��� (� ������� �����, �� ������� �����):"
		elseif (scriptTEMPSETID == 2) then
			dcon = dcon .. "{FFFFFF}������� {F0BD48}������� {FFFFFF} ������ ������.\n�����, ����� ������� ��������������� ������ ����� �������� ����.\n\n������� ������� (� ������� �����, �� ������� �����):"
		elseif (scriptTEMPSETID == 3) then
			dcon = dcon .. "{FFFFFF}������� {F0BD48}��������� {FFFFFF} ������ ������.\n�����, ����� ������� ��������������� ��������� ����� ���������.\n\n������� ��������� (� ������� �����, �� ������� �����):"
		elseif (scriptTEMPSETID == 4) then
			dtyp = DS_LIST
			dcon = dcon .. "�������\n�������"
		end
	elseif (dialogid == dlgEXTRA) then
		dcap = "{00BFFF}�������������� ���������"; dbut1 = "��������"; dbut2 = "�����"; dtyp = DS_TABHEAD
		dcon = dcon .. "��������\t��������\n\
			1. �������������� �������\t" .. (config.func.dub and "{84DD2A}���" or "{DD2A2A}����") .. "\n"
		dcon = dcon .. "2. ��������� ���������� (/cuff)\t" .. (config.func.cuff and "{84DD2A}���" or "{DD2A2A}����") .. "\n\
			3. ��������� ������� (/hold)\t" .. (config.func.follow and "{84DD2A}���" or "{DD2A2A}����") .. "\n\
			4. ��������� ������� � ���������� (/putpl)\t" .. (config.func.tocar and "{84DD2A}���" or "{DD2A2A}����") .. "\n"
	elseif (dialogid == dlgSCROPT) then
		dcap = "{00BFFF}��������� �������"; dbut1 = "��������"; dbut2 = "�����"; dtyp = DS_TABHEAD
		dcon = dcon .. "��������\t��������\n\
			1. ���������� ��� � ����\t" .. (config.other.timestamp and "{84DD2A}���" or "{DD2A2A}����")
	elseif (dialogid == dlgUPDATE) then
		tryToUpdateScript(true)
		dcap = "{00BFFF}���������� �������"; dtyp = DS_MSGBOX
		dcon = dcon .. "{FFFFFF}������� ������: {DE4343}" .. tostring(VERSION) .. "\n"
		dcon = dcon .. "{FFFFFF}���������� ������: {43DEDE}" .. tostring(ACTUAL) .. "\n\n"
		if (VERSION ~= ACTUAL) then
			dbut1 = "��������"; dbut2 = "�����";
			dcon = dcon .. "{FFFFFF}������� ������ {DECC43}�������� {FFFFFF}��� �������� ����� ������."
		else
			dbut1 = "�����"; dbut2 = "�������";
			dcon = dcon .. "{FFFFFF}� ��� ����������� ��������� ������ �������."
		end
	else dvalid = false end
	if dvalid == true then sampShowDialog(dialogid, dcap, dcon, dbut1, dbut2, dtyp) end
end

-- Dialog Response -- -- ------------------------
function onDialogRespone()
	local dlgR, dlgB, dlgL, dlgI = sampHasDialogRespond(dlgMAIN)
	if (dlgR == true and dlgB == 1) then
		if dlgL == 0 then showDlg(dlgCMDS)
		elseif dlgL == 1 then showDlg(dlgSETLIST)
		elseif dlgL == 2 then showDlg(dlgEXTRA)
		elseif dlgL == 3 then showDlg(dlgSCROPT)
		elseif dlgL == 4 then showDlg(dlgUPDATE)
		end
	end

	dlgR, dlgB, dlgL, dlgI = sampHasDialogRespond(dlgCMDS)
	if (dlgR == true and dlgB == 1) then
		showDlg(dlgMAIN)
	end

	dlgR, dlgB, dlgL, dlgI = sampHasDialogRespond(dlgSETLIST)
	if (dlgR == true) then
		if (dlgB == 1) then
			scriptTEMPSETID = dlgL
			showDlg(dlgSETUP)
		elseif (dlgB == 0 and scriptENTERDATA == false) then showDlg(dlgMAIN)
		end
	end

	dlgR, dlgB, dlgL, dlgI = sampHasDialogRespond(dlgSETUP)
	if (dlgR == true) then
		if (dlgB == 1) then
			if (scriptTEMPSETID == 0) then
					if(#dlgI == 0) then
						local plares, plaid = sampGetPlayerIdByCharHandle(playerPed)
						local planik = sampGetPlayerNickname(plaid)
						config.main.nick = planik
					else
						config.main.nick = dlgI
					end
			elseif (scriptTEMPSETID == 1) then config.main.fname = dlgI
			elseif (scriptTEMPSETID == 2) then config.main.lname = dlgI
			elseif (scriptTEMPSETID == 3) then config.main.rang = dlgI
			elseif (scriptTEMPSETID == 4) then config.main.sex = (dlgL == 0 and true or false)
			end
			saveConfigs()
		end
		showDlg(dlgSETLIST)
	end

	dlgR, dlgB, dlgL, dlgI = sampHasDialogRespond(dlgEXTRA)
	if (dlgR == true) then
		if (dlgB == 1) then
			if (dlgL == 0) then config.func.dub = not config.func.dub
			elseif (dlgL == 1) then config.func.cuff = not config.func.cuff
			elseif (dlgL == 2) then config.func.follow = not config.func.follow
			elseif (dlgL == 3) then config.func.tocar = not config.func.tocar
			end
			saveConfigs()
			showDlg(dlgEXTRA)
		else showDlg(dlgMAIN)
		end
	end

	dlgR, dlgB, dlgL, dlgI = sampHasDialogRespond(dlgSCROPT)
	if (dlgR == true) then
		if (dlgB == 1) then
			if (dlgL == 0) then config.other.timestamp = not config.other.timestamp
			end
			saveConfigs()
			showDlg(dlgSCROPT)
		else showDlg(dlgMAIN)
		end
	end

	dlgR, dlgB, dlgL, dlgI = sampHasDialogRespond(dlgUPDATE)
	if (dlgR == true) then
		if (VERSION ~= ACTUAL) then
			if (dlgB == 1) then tryToUpdateScript(false)
			else showDlg(dlgMAIN)
			end
		else
			if (dlgB == 1) then showDlg(dlgMAIN)
			end
		end
	end

end

-- -- Other functions -- -- --
function getPlaLine(strline)
	for i = 0, 999 do
		if sampIsPlayerConnected(i) and string.find(strline, sampGetPlayerNickname(i)) then
			return i, sampGetPlayerNickname(i)
		end
	end
	return -1, ""
end

function fixNick(nickline)
	return string.gsub(nickline, "_", " ")
end

function getAnglePla(cX, cY, pX, pY)
	local x = pX - cX
	local y = pY - cY
	if (x == 0) then
		if (y > 0) then return 180
		else return 0
		end
	end
	local ang = math.atan(y / x) * 180 / math.pi
	ang = (x > 0) and ang + 90 or ang + 270
	ang = ang + 180
	return ang
end

function getDistPla(x1, y1, z1, x2, y2, z2)
	return math.sqrt( math.pow(x2-x1, 2) + math.pow(y2-y1, 2) + math.pow(z2-z1, 2) )
end
