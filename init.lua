-- quiz/init.lua
local MOD_NAME = minetest.get_current_modname()

if rawget(_G, MOD_NAME) then return end

quiz = {}
minetest.log("info", "Loading quiz Mod")

-- local defaultS = default.get_translator

local store = minetest.get_mod_storage()
local MOD_PATH = minetest.get_modpath(MOD_NAME) .. "/"
-- local WORLD_PATH = minetest.get_worldpath() .. "/"
local mergeTable = dofile(MOD_PATH .. "merge_table.lua")
local array = dofile(MOD_PATH .. "array.lua")

-- Load support for MT game translation.
local S = minetest.get_translator(MOD_NAME)
--  escapes the characters "[", "]", "\", "," and ";", which can not be used in formspecs.
local esc = minetest.formspec_escape

local settings = yaml.readConfig(MOD_NAME, "config.yml")
-- print(dump(mod_setting));

quiz.MOD_NAME = MOD_NAME
quiz.MOD_PATH = MOD_PATH
quiz.settings = settings
quiz.store    = store
quiz.get_translator = S

local quizzes = dofile(MOD_PATH .. "quizzes.lua")
quiz.quizzes = quizzes

local givemeItem = dofile(MOD_PATH.."giveme_item.lua")
local isOnline = dofile(MOD_PATH.."is_online.lua")

-- LUALOCALS < ---------------------------------------------------------
local minetest, pairs, type
    = minetest, pairs, type
-- LUALOCALS > ---------------------------------------------------------

local dialogClosed = true
-- collects the fields of a player
local curFields = {}

local function getFields(playerName)
  local result = curFields[playerName]
  if result == nil then
    result = {}
    curFields[playerName] = result
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

local function get_formspec(player_name, quiz)
  local fields = getFields(player_name)
  player_name = esc(S("Hi, @1", player_name) .. "," .. S("the challenge begins!"))
  local title = esc(quizzes.getTitle(quiz) or "")
  local desc = esc(quiz.desc or "")
  local questionStr = esc(S("Question"))
  local answerStr = esc(S("Answer"))
  local formspec = {
    "formspec_version[4]",
    "size[10,9]",
    "box[0.4,1.1;9.2,4.25;#999999]",
    "textarea[0.4,1.1;9.2,4.25;;",questionStr, ";" , title, "]",
  }
  if desc and desc ~= "" then table.insert(formspec, "label[1.8,0.8;(".. desc ..")]") end
  table.insert(formspec, "button_exit[3.2,8;3.5,0.8;ok;Ok]")
  local options = mergeTable({}, quiz.options)
  array.shuffle(options)
  fields._options = options
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

local huds = {}
local allAnswered = {}
local joinTime = {}

local function resetWhenLeaving(playerName)
  huds[playerName] = nil
  allAnswered[playerName] = nil
  local enterTime = joinTime[playerName] or 0
  -- joinTime[playerName] = nil
  local currTime = os.time()
  local usedTime = getUsedTime(playerName) + currTime - enterTime
  if enterTime and (usedTime > 0) then
    setLastLeavedTime(playerName, currTime)
    setUsedTime(playerName, usedTime)
  end
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

      local playerHud = huds[pname]

      local hasPriv = minetest.check_player_privs(player, "interact")

      if hasPriv then
        player:hud_set_flags({crosshair = true})
        if playerHud then
          for _, id in pairs(playerHud) do
            player:hud_remove(id)
          end
        end
        huds[pname] = nil
        return
      end

      player:hud_set_flags({crosshair = false})
      if not playerHud then
        playerHud = {}
        huds[pname] = playerHud
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
  local qOptions = quiz.options
  if quiz and quiz.type == "select" and #qOptions then
    answer = {}
    local options = fields.options
    for i=1, #qOptions do
      if fields["opt" .. i] == "true" then
        table.insert(answer, array.find(options[i]))
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
      if not allAnswered[playerName] then
        grantPriv(playerName)
        minetest.chat_send_all(errmsg)
        allAnswered[playerName] = true
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
  -- if (not aPlayer) then return end
  -- local playerName = aPlayer:get_player_name()
  -- get the current quiz if no answer passed
  local quiz, errmsg = checkAnswer(playerName)

  if quiz and errmsg then return end
  -- print('TCL:: ~ file: init.lua ~ line 112 ~ playerName', playerName);

  local function on_close(state, player, fields)
    state = getFields(playerName)
    mergeTable(state, fields)
    -- print('TCL:: ~ file: init.lua ~ line 288 ~ onclose player:', playerName, dump(state));
    if fields.quit == minetest.FORMSPEC_SIGTIME then -- timeout reached
      local vQuiz, vErrmsg = quizzes.getCurrent(playerName)
      if vQuiz and not vErrmsg then
        minetest.update_form(playerName, get_formspec(playerName, vQuiz))
        return
      end
      -- local result = checkAnswer(playerName, fields.answer, vQuiz)
    end
    dialogClosed = true
    if fields.quit == "true" then
      checkAnswer(playerName, state, quiz)
      curFields[playerName] = {}
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
    dialogClosed = false
    minetest.create_form(nil, playerName, get_formspec(playerName, quiz), on_close)
    -- minetest.get_form_timer(playerName).start(1)
    return true
  end
end
quiz.openQuizView = openQuizView

local function checkGameTime(playerName)
  local currTime = os.time()
  local kickDelay = settings.kickDelay or 60
  local lastJoinTime = joinTime[playerName] or 0
  joinTime[playerName] = currTime
  -- local checkInterval = settings.checkInterval
  local lastLeavedTime = getLastLeavedTime(playerName)
  local lastUsedTime = getUsedTime(playerName) or 0
  local restTime = (settings.restTime or 0) * 60
  local realRestTime = currTime - lastLeavedTime
  -- print('TCL:: ~ file: init.lua ~ line 285 ~ register_on_joinplayer lastUsedTime', lastUsedTime);
  local totalPlayTime = settings.totalPlayTime * 60 - lastUsedTime
  -- print("register_on_joinplayer:", playerName, settings.restTime, totalPlayTime, lastLeavedTime)
  if totalPlayTime <= 0 and restTime > 0 and lastLeavedTime then
    if (realRestTime < restTime) then
      local leftRestTime = math.floor((restTime - realRestTime) / 60 + 0.5)
      minetest.chat_send_player(playerName, S("Hi, @1", playerName) .. ".\n" ..
        S("The rest time is not over, please continue to rest your eyes.") .. "\n" ..
        S("You have to rest for another @1 minutes.", leftRestTime) .. "\n" ..
        S("You should quit game.") .. "\n" ..
        S("It will automatically exit after 1 minute.")
      )
      minetest.after(kickDelay, function()
        kickPlayer(playerName, S("The rest time is not over, please continue to rest your eyes.") .. "\n" ..
          S("You have to rest for another @1 minutes.", leftRestTime)
        )
      end)
    else
      totalPlayTime = settings.totalPlayTime * 60
    end
  end
  if totalPlayTime > 0 then
    setUsedTime(playerName, 0)
    minetest.after(totalPlayTime, function()
      if isOnline(playerName) then
        minetest.chat_send_player(playerName, S("Hi, @1", playerName) .. ".\n" ..
          S("Game time is over, please rest your eyes.") .. "\n" ..
          S("You should quit game.") .. "\n" ..
          S("It will automatically exit after 1 minute.")
        )
        minetest.after(kickDelay, function()
          kickPlayer(playerName, S("Game time is over, please rest your eyes."))
        end)
      end
    end)
  end
end

minetest.register_on_joinplayer(function(player)
  local playerName = player:get_player_name()
  local isAdmin = minetest.check_player_privs(player, "quiz")

  if settings.forceAdminRest or not isAdmin then checkGameTime(playerName) end
  -- minetest.is_singleplayer()
  if isAdmin then return end

  local function doCheck()
    local checkInterval = settings.checkInterval
    -- print("doCheck interval:", checkInterval)

    if (player) then hudcheck(playerName) end
    local isNeedQuiz = type(playerName) == "string" and (not minetest.check_player_privs(playerName, "quiz") or settings.forceAdminQuiz)
    if (dialogClosed and isNeedQuiz) then openQuizView(playerName) end

    if (checkInterval > 0) and isOnline(playerName) then
      -- execute after checkInterval seconds
      minetest.after(checkInterval, doCheck)
    end
  end

  local delay = 0
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
