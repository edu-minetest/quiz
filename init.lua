-- quiz/init.lua
-- LUALOCALS < ---------------------------------------------------------
local minetest, pairs, type, DIR_DELIM
    = minetest, pairs, type, DIR_DELIM
-- LUALOCALS > ---------------------------------------------------------

local MOD_NAME = minetest.get_current_modname()

if rawget(_G, MOD_NAME) then return end

quiz = {}
minetest.log("info", "Loading quiz Mod")

-- Handle mod security if needed
local ie, req_ie = _G, minetest.request_insecure_environment
if req_ie then ie = req_ie() end
quiz.trusted = not not ie

-- local defaultS = default.get_translator

local mkdir = minetest.mkdir
local store = minetest.get_mod_storage()
local MOD_PATH = minetest.get_modpath(MOD_NAME) .. DIR_DELIM
local WORLD_PATH = minetest.get_worldpath() .. DIR_DELIM
local STUDENTS_PATH = WORLD_PATH .. MOD_NAME .. DIR_DELIM .."students" .. DIR_DELIM

local function isWritenModDir()
  local modName = minetest.get_current_modname()
  return not not modName
end

if type(minetest.get_mod_data_path) == "function" then
  STUDENTS_PATH = minetest.get_mod_data_path() .. DIR_DELIM .. "students" .. DIR_DELIM
--[[
elseif isWritenModDir() then
  if ie then -- write to mod_data directory
    -- "(.*/)worlds/.*/": get minetest main directory
    local pattern = "(.*" .. DIR_DELIM .. ")worlds" .. DIR_DELIM .. ".*" .. DIR_DELIM
    local p = string.match(WORLD_PATH, pattern)
    local modDataDir =  "mod_data" .. DIR_DELIM .. MOD_NAME .. DIR_DELIM
    if p ~= nil then modDataDir = p .. modDataDir end
    STUDENTS_PATH = modDataDir .. "students" .. DIR_DELIM
  else
    STUDENTS_PATH = MOD_PATH .. "students" .. DIR_DELIM
  end
--]]
end

local mergeTable = dofile(MOD_PATH .. "merge_table.lua")
local array = dofile(MOD_PATH .. "array.lua")

-- Load support for MT game translation.
local S = minetest.get_translator(MOD_NAME)
--  escapes the characters "[", "]", "\", "," and ";", which can not be used in formspecs.
local esc = minetest.formspec_escape

local settings = yaml.readConfig(MOD_NAME, "config.yml", {"quiz"})
-- print(dump(mod_setting));

quiz.MOD_NAME = MOD_NAME
quiz.MOD_PATH = MOD_PATH
quiz.settings = settings
quiz.store    = store
quiz.get_translator = S

local givemeItem = dofile(MOD_PATH.."giveme_item.lua")
local isOnline = dofile(MOD_PATH.."is_online.lua")

-- collects the player's sessions
local sessions = {}
quiz.sessions = sessions

local function getSession(playerName)
  if type(playerName) ~= "string" then
    playerName = playerName:get_player_name()
  end
  local result = sessions[playerName]
  if result == nil then
    result = {}
    sessions[playerName] = result
    result.dialogClosed = true
  end
  return result
end
quiz.getSession = getSession

local function clearSession(playerName)
  local result = sessions[playerName]
  if result ~= nil then
    sessions[playerName] = nil
  end
end
quiz.clearSession = clearSession

local function getFields(playerName, session)
  if session == nil then session = getSession(playerName) end
  local result = session.fields
  if result == nil then
    result = {}
    session.fields = result
  end
  return result
end

local function getLastLeavedTime(playerName)
  return store:get_int(playerName .. ":leavedTime")
end
quiz.getLastLeavedTime = getLastLeavedTime

-- record the last leaved time of a player
local function setLastLeavedTime(playerName, value)
  return store:set_int(playerName ..":leavedTime", value)
end
quiz.setLastLeavedTime = setLastLeavedTime

-- TODO: use this minetest.get_player_information(name).connection_uptime
local function getUsedTime(playerName)
  return store:get_int(playerName .. ":usedTime")
end
quiz.getUsedTime = getUsedTime

-- record the last used time of a player
local function setUsedTime(playerName, value)
  return store:set_int(playerName ..":usedTime", value)
end
quiz.setUsedTime = setUsedTime

local function logQuiz(playerName, quiz, answer, ok)
  -- print("logQuiz: current mod name:", minetest.get_current_modname())
  local session = getSession(playerName)
  local logDir = STUDENTS_PATH .. playerName
  local logFile =  logDir .. "/quiz-log.yml"
  mkdir(logDir)
  local content = {}
  if quiz.type == "calc" then
    content["title"] = quiz.calc
    -- content["real_answer"] = quiz["real_answer"]
  else
    content["title"] = quiz.title
  end
  content["type"] = quiz.type or "text"
  if quiz.options then content["options"] = quiz.options end

  mergeTable(content, {
    answer = answer, ok = ok,
    start = os.date("%Y-%m-%dT%H:%M:%S", session.startQuizTime),
    answerTime = session.answerTime
  })
  yaml.writeFile(logFile, {content}, "a")
end
quiz.logQuiz = logQuiz

local quizzes = dofile(MOD_PATH .. "quizzes.lua")
quiz.quizzes = quizzes

local function get_formspec(player_name, quiz, session)
  local fields = getFields(player_name, session)
  player_name = esc(S("Hi, @1", player_name) .. "," .. S("the challenge begins!"))
  local title = esc(quizzes.getTitle(quiz) or "")
  local desc = esc(quiz.desc or "")
  local questionStr = esc(S("Question"))
  local answerStr = esc(S("Answer"))
  local formspec = {
    "formspec_version[4]",
    "size[10,9]",
    "label[0,0.2;", player_name, "]",
    "box[0.4,1.1;9.2,4.25;#999999]",
    "textarea[0.4,1.1;9.2,4.25;;",questionStr, ";" , title, "]",
  }
  if desc and desc ~= "" then table.insert(formspec, "label[1.8,0.8;(".. desc ..")]") end
  table.insert(formspec, "button_exit[3.2,8;3.5,0.8;ok;Ok]")
  local options = fields._options
  if options == nil then
    options = mergeTable({}, quiz.options)
    array.shuffle(options)
    fields._options = options
  end
  if quiz.type == "select" and options and #options then
    local ox = 0.5
    local oy = 5.9
    local x = ox
    local y = oy
    local columnCount = 3
    for i=1,#options do
      local fraq = (i-1) % columnCount
      x = ox + fraq * 3.5
      y = oy + math.modf((i-1) / columnCount) * 0.6
      table.insert(formspec, "checkbox[".. x .. "," .. y .. ";opt".. i .. ";" .. options[i] .. "]")
      if fraq == (columnCount - 1) then x = ox end
    end
  else
    table.insert(formspec, "field[0.4,6;9.2,0.9;answer;" .. answerStr .. ";]")
  end

  -- table.concat is faster than string concatenation - `..`
  return table.concat(formspec, "")

end

-- local motddesc = conf("get", "desc") or "terms"

local cmdname = settings.cmdName or S("answer")
-- local cmdparam = conf("get", "cmdparam") or ("to " .. motddesc)
local cmdDesc = settings.cmdDesc or S("type /@1 your answer in chat window", cmdname)

-- display two messages on HUD
local hudline1 = settings.hudline1 or S("You must answer the question to play.")
local hudline2 = settings.hudline2 or cmdDesc

local function resetWhenLeaving(playerName)
  local session = getSession(playerName)

  local enterTime = session.joinTime or 0
  local currTime = os.time()
  local usedTime = currTime - enterTime
  if enterTime then
    setLastLeavedTime(playerName, currTime)
    if usedTime >= settings.totalPlayTime * 60 then
      setUsedTime(playerName, 0)
    elseif usedTime >= 30 then
      setUsedTime(playerName, usedTime)
    end
  end
  clearSession(playerName)
end

local function kickPlayer(playerName, reason)
  -- resetWhenLeaving(playerName)
  minetest.log("action", playerName .. " was kicked for " .. reason)
  minetest.kick_player(playerName, reason)
end

-- create or update HUD
local function showHud(player, id, offset, text)
  if not id then
    return player:hud_add({
        hud_elem_type = "text",
        position = {x = 0.5, y = 0.5},
        text = text,
        number = 0xFFC000,
        alignment = {x = 0, y = offset},
        offset = {x = 0, y = offset}
      })
  end
  player:hud_change(id, "text", text)
  return id
end

local function hudcheck(pname)
  if not pname then return end
  pname = type(pname) == "string" and pname or pname:get_player_name()
  minetest.after(0, function()
      local player = minetest.get_player_by_name(pname)
      if not player then return end
      local session = getSession(pname)

      local playerHud = session.huds

      local hasPriv = minetest.check_player_privs(player, "interact")

      if hasPriv then
        player:hud_set_flags({crosshair = true})
        if playerHud then
          for _, id in pairs(playerHud) do
            player:hud_remove(id)
          end
        end
        session.huds = nil
        return
      end

      player:hud_set_flags({crosshair = false})
      if not playerHud then
        playerHud = {}
        session.huds = playerHud
      end
      playerHud[1] = showHud(player, playerHud[1], -1, hudline1)
      if hudline2 and #hudline2 then
        playerHud[2] = showHud(player, playerHud[2], 1, hudline2)
      end
    end)
end

local function revokePriv(playerName)
  local grant = minetest.string_to_privs(settings.grant or "interact,shout")
  local privs = minetest.get_player_privs(playerName)
  -- print('TCL:: ~ file: init.lua ~ line 139 ~ revokePrivs', playerName, dump(privs));
  if #privs then
    for priv in pairs(grant) do
      privs[priv] = nil
      -- minetest.run_priv_callbacks(playerName, priv, playerName, "revoke")
    end
    minetest.set_player_privs(playerName, privs)
    -- privs = minetest.get_player_privs(playerName)
    -- print('TCL:: ~ file: init.lua ~ line 139 ~ revokePrivs result', playerName, dump(privs));
    hudcheck(playerName)
  end
end

local function grantPriv(playerName)
  local grant = minetest.string_to_privs(settings.grant or "interact,shout")
  local privs = minetest.get_player_privs(playerName)
  local needUpdate = false
  for priv in pairs(grant) do
    if not privs[priv] then needUpdate = true end
    privs[priv] = true
    -- minetest.run_priv_callbacks(playerName, priv, playerName, "grant")
  end
  if needUpdate then
    minetest.set_player_privs(playerName, privs)
    -- print('TCL:: ~ file: init.lua ~ line 139 ~ grantPrivs', dump(privs));
    hudcheck(playerName)
  end
end

local function checkAnswer(playerName, fields, quiz)
  local answer
  local session = getSession(playerName)
  if not session.online then return end
  if quiz and quiz.type == "select" and #quiz.options then
    answer = {}
    local options = fields._options
    for i=1, #quiz.options do
      if fields["opt" .. i] == "true" then
        table.insert(answer, array.find(quiz.options, options[i]))
      end
    end
  else
    answer = fields and fields.answer
  end

  -- local playerName = aPlayer:get_player_name()
  local result, errmsg = quizzes.check(playerName, answer, quiz)
  -- print('TCL:: ~ file: checkAnswer.lua ~ line 235 ~ result', dump(result), dump(errmsg));
  if errmsg then
    if result then
      -- all questions are answered!
      if not session.allAnswered then
        grantPriv(playerName)
        minetest.chat_send_all(errmsg)
        session.allAnswered = true
      end
      return true
    else
      revokePriv(playerName)
      minetest.chat_send_player(playerName, errmsg)
    end
  else
    -- local result, msg = quizzes.check(aPlayer, answer, quiz)
    if result == true then
      grantPriv(playerName)
      minetest.chat_send_all(S("Congratuation @1, you got the answer!", playerName))
      -- NodeItem CraftItem and ToolItem
      local awards = settings.awards
      if (#awards) then
        local ix = math.random(#awards)
        local v = givemeItem(playerName, awards[ix])
        -- print("givemeItem to", playerName, dump(v))
      end
      return true
    elseif answer and answer ~= "" then
      minetest.chat_send_player(playerName, S("Hi, @1", playerName) .. "." ..
        S("Sorry, the answer is not right, think it carefully")
      )
    elseif result == nil then
      grantPriv(playerName)
      return result
    end
  end
  revokePriv(playerName)
  return result, errmsg
end

local function openQuizView(playerName)
  local player = minetest.get_player_by_name(playerName)
  if not player or player:get_hp() <= 0 then return end

  -- if (not aPlayer) then return end
  -- local playerName = aPlayer:get_player_name()
  -- get the current quiz if no answer passed
  local quiz, errmsg = checkAnswer(playerName)
  local session = getSession(playerName)
  session.startQuizTime = os.time()

  if quiz and errmsg then return end
  -- print('TCL:: ~ file: init.lua ~ line 112 ~ playerName', playerName);

  local function on_close(state, player, fields)
    local playerName = player:get_player_name()
    local session = getSession(playerName)
    state = getFields(playerName, session)
    mergeTable(state, fields)
    -- print('TCL:: ~ file: init.lua ~ line 364 ~ onclose player fields:', playerName, dump(fields));
    -- print('TCL:: ~ file: init.lua ~ line 365 ~ onclose player state:', playerName, dump(state));
    if fields.quit == minetest.FORMSPEC_SIGTIME then -- timeout reached
      local vQuiz, vErrmsg = quizzes.getCurrent(playerName)
      if vQuiz and not vErrmsg then
        minetest.update_form(playerName, get_formspec(playerName, vQuiz, session))
        return
      end
      -- local result = checkAnswer(playerName, fields.answer, vQuiz)
    end
    session.dialogClosed = true
    if fields.quit == "true" then
      local answerTime = os.time() - session.startQuizTime
      session.answerTime = answerTime
      if checkAnswer(playerName, state, quiz) and answerTime <= 60 then
        session.extraDelay = (session.extraDelay or 0) + 60
      end
      session.fields = {}
    end
    --   minetest.update_form(playerName, get_formspec(playerName, quiz.title, quiz.desc))
    -- elseif fields.answer and quiz.answer == fields.answer then
    --   minetest.get_form_timer(playerName).stop()
    --   minetest.chat_send_all("Cool, you are successful!")
    -- else
    --   minetest.get_form_timer(playerName).start(1)
    -- end
  end

  if (type(quiz) == "table") then
    session.dialogClosed = false
    minetest.create_form(nil, playerName, get_formspec(playerName, quiz, session), on_close)
    -- minetest.get_form_timer(playerName).start(1)
    return true
  end
end
quiz.openQuizView = openQuizView

local function disp_time(time)
  local result = ""
  if time < 0 then
    result = "- "
    time = -time
  end
  local days = math.floor(time/86400)
  if days > 0 then result = result .. S("@1 day(s)", days) end
  local hours = math.floor(math.fmod(time, 86400)/3600)
  if hours > 0 then result = result .. " " .. S("@1 hour(s)", hours) end
  local minutes = math.floor(math.fmod(time,3600)/60)
  if minutes > 0 then result = result .. " " .. S("@1 minute(s)", minutes) end
  local seconds = math.floor(math.fmod(time,60))
  if seconds > 0 then result = result .. " " .. S("@1 second(s)", seconds) end
  return result
end

local function checkGameTime(playerName)
  local session = getSession(playerName)
  local currTime = os.time()
  local kickDelay = settings.kickDelay or 1
  -- local lastJoinTime = joinTime[playerName] or 0
  -- local checkInterval = settings.checkInterval
  local lastLeavedTime = getLastLeavedTime(playerName) or currTime
  local lastUsedTime = getUsedTime(playerName) or 0
  local restTime = (settings.restTime or 0) * 60
  local realRestTime = currTime - lastLeavedTime
  -- print('TCL:: ~ file: init.lua ~ line 285 ~ register_on_joinplayer lastUsedTime', lastUsedTime);
  session.totalPlayTime = settings.totalPlayTime
  local leftPlayTime = settings.totalPlayTime * 60 - lastUsedTime
  local leftRestTime = math.floor((restTime - realRestTime) + 0.5)
  -- print("register_on_joinplayer:", playerName, settings.restTime, session.totalPlayTime, lastLeavedTime, restTime, leftRestTime)
  if restTime > 0 and leftRestTime > 0 then
    if leftPlayTime <= 0 then
      minetest.chat_send_player(playerName, S("Hi, @1", playerName) .. ".\n" ..
        S("The rest time is not over, please continue to rest your eyes.") .. "\n" ..
        S("You have to rest for another @1.", disp_time(leftRestTime)) .. "\n" ..
        S("You should quit game.") .. "\n" ..
        S("It will automatically exit after @1.", kickDelay / 60)
      )
      if session.kickJob then
        session.kickJob:cancel()
        session.kickJob = nil
      end
      if kickDelay == 0 then
        kickPlayer(playerName, S("The rest time is not over, please continue to rest your eyes.") .. "\n" ..
          S("You have to rest for another @1.", disp_time(leftRestTime))
        )
      elseif kickDelay > 0 then
        session.kickJob = minetest.after(kickDelay, function()
          kickPlayer(playerName, S("The rest time is not over, please continue to rest your eyes.") .. "\n" ..
            S("You have to rest for another @1.", disp_time(leftRestTime))
          )
        end)
      end
      return
    end
  else
    leftPlayTime = settings.totalPlayTime * 60
  end
  -- print("checkGameTime", leftPlayTime, "seconds")
  if leftPlayTime > 0 then
    setUsedTime(playerName, 0)
    if session.kickJob then session.kickJob:cancel() end
    session.kickJob = minetest.after(leftPlayTime, function()
      if isOnline(playerName) then
        local restTimeMin = math.modf(restTime / 60)
        local extraDelay = session.extraDelay or 0
        minetest.chat_send_player(playerName, S("Hi, @1", playerName) .. ".\n" ..
          S("Game time is over, please rest your eyes for at least @1 minutes.", restTimeMin) .. "\n" ..
          S("You should quit game.") .. "\n" ..
          S("It will automatically exit after @1.", disp_time(kickDelay + extraDelay))
        )
        minetest.after(kickDelay + extraDelay, function()
          kickPlayer(playerName, S("Game time is over, please rest your eyes for at least @1 minutes.", restTimeMin))
        end)
      end
    end)
  end
end
quiz.checkGameTime = checkGameTime

local function resetGameTime(playerName)
  if playerName then
    setLastLeavedTime(playerName, 0)
    setUsedTime(playerName, 0)
    local player = minetest.get_player_by_name(playerName)
    if player then
      local isAdmin = minetest.check_player_privs(player, "quiz")
      if settings.forceAdminRest or not isAdmin then checkGameTime(playerName) end
    end
  end
end
quiz.resetGameTime = resetGameTime

minetest.register_on_joinplayer(function(player)
  local playerName = player:get_player_name()
  local isAdmin = minetest.check_player_privs(player, "quiz")
  local session = getSession(playerName)
  session.joinTime = os.time()
  session.online = true

  if settings.forceAdminRest or not isAdmin then checkGameTime(playerName) end
  -- minetest.is_singleplayer()
  if isAdmin then return end

  local function doCheck()
    local checkInterval = settings.checkInterval
    -- print("doCheck interval:", checkInterval)

    if (player) then hudcheck(playerName) end
    local isNeedQuiz = type(playerName) == "string"
      and not minetest.check_player_privs(playerName, "noquiz")
      and (not minetest.check_player_privs(playerName, "quiz") or settings.forceAdminQuiz)
    if (session.dialogClosed and isNeedQuiz) then openQuizView(playerName) end

    if (checkInterval > 0) and isOnline(playerName) then
      -- execute after checkInterval seconds
      minetest.after(checkInterval, doCheck)
    end
  end

  local delay = settings.immediateDelay or 30
  if settings.immediateQuiz == false then
    delay = (settings.idleInterval or 5) * 60 --> defaults to 5 min.
  end

  if (settings.checkInterval > 0) then
    minetest.after(delay, doCheck)
  else
    minetest.after(delay, function()
      hudcheck(playerName)
      openQuizView(playerName)
    end)
  end

end)

minetest.register_on_leaveplayer(function(player)
  local playerName = player:get_player_name()
  local session = getSession(playerName)
  session.online = nil
  grantPriv(playerName)
  resetWhenLeaving(playerName)
  minetest.log("info", S("@1 has leaved", playerName))
  minetest.chat_send_all(S("@1 has leaved", playerName))
end)

-- minetest.register_privilege(MOD_NAME, {
--     description = S("manage to quiz"),
--     give_to_singleplayer = false,
--     give_to_admin = false,
--     on_grant = hudcheck,
--     on_revoke = hudcheck
--   })

-- register chat commands
dofile(MOD_PATH.."chat_cmds.lua")
