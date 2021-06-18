-- play_challenge/init.lua

local MOD_NAME = minetest.get_current_modname()
local MOD_PATH = minetest.get_modpath(MOD_NAME) .. "/"
-- local WORLD_PATH = minetest.get_worldpath() .. "/"

-- Load support for MT game translation.
local S = minetest.get_translator(MOD_NAME)
--  escapes the characters "[", "]", "\", "," and ";", which can not be used in formspecs.
local esc = minetest.formspec_escape

--< debug only
dump = require 'pl.pretty'.dump

local settings = yaml.readConfig("config.yml", MOD_PATH)
-- print(dump(mod_setting));

play_challenge = rawget(_G, MOD_NAME) or {}
play_challenge.MOD_NAME = MOD_NAME
play_challenge.modpath = MOD_PATH
play_challenge.settings = settings
-- play_challenge.mod_settings = mod_settings
-- play_challenge.world_settings = world_settings

play_challenge.current = 0
-- play_challenge.quiz = {}  ---- the quiz list
play_challenge.get_translator = S

-- LUALOCALS < ---------------------------------------------------------
local minetest, pairs, type
    = minetest, pairs, type
-- LUALOCALS > ---------------------------------------------------------

local quizzes = dofile(MOD_PATH .. "quizzes.lua")

local dialogClosed = true

local function get_formspec(player_name, title, desc)
  local text = esc(S("Hi @1, the challenge begins!", player_name))
  title = esc(title)
  if desc then desc = esc(desc) end
  local formspec = {
    "formspec_version[4]",
    "size[8,6]",
    "label[0,0.2;", text, "]",
    "label[0.4,0.8;", title, "]",
    "field[0.2,1.5;5.6,0.9;answer;Answer;]",
  }
  if desc then formspec[#formspec+1] = "label[0.1,2.7;".. desc .."]" end
  formspec[#formspec+1] = "button_exit[1.8,3.2;3.5,0.8;ok;Ok]"

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
  pname = type(pname) == "string" and pname or pname:get_player_name()
  minetest.after(0, function()
      local player = minetest.get_player_by_name(pname)
      if not player then return end

      local playerHud = huds[pname]

      local hasPriv = minetest.check_player_privs(player, "interact")
      print('TCL:: ~ file: init.lua ~ line 248 ~ hasPriv', hasPriv);

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

minetest.register_on_leaveplayer(function(player)
    huds[player:get_player_name()] = nil
end)

local function revokePriv(playerName)
  local grant = minetest.string_to_privs(settings.grant or "interact")
  local privs = minetest.get_player_privs(playerName)
  for priv in pairs(grant) do
    privs[priv] = false
    minetest.run_priv_callbacks(playerName, priv, playerName, "revoke")
  end
  minetest.set_player_privs(playerName, privs)
  print('TCL:: ~ file: init.lua ~ line 130 ~ revokePrivs', dump(privs));
  hudcheck(playerName)
end

local function grantPriv(playerName)
  local grant = minetest.string_to_privs(settings.grant or "interact")
  local privs = minetest.get_player_privs(playerName)
  for priv in pairs(grant) do
    privs[priv] = true
    minetest.run_priv_callbacks(playerName, priv, playerName, "grant")
  end
  minetest.set_player_privs(playerName, privs)
  hudcheck(playerName)
end

local function checkAnswer(aPlayer, answer, quiz)
  local playerName = aPlayer:get_player_name()
  local result, errmsg = quizzes.check(aPlayer, answer, quiz)
  print('TCL:: ~ file: init.lua ~ line 144 ~ checkAnswer result', result);
  if errmsg then
    if result then
      -- all questions are answered!
      grantPriv(playerName)
      minetest.chat_send_all(playerName .. ":" .. errmsg)
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
      -- quizzes.next(playerName)
      return true
    elseif answer and answer ~= "" then
      minetest.chat_send_player(playerName, S("Hi @1. Sorry, the answer is not right, think it carefully", playerName))
    end
  end
  revokePriv(playerName)
  return result, errmsg
end

local function openQuizView(aPlayer)
  local playerName = aPlayer:get_player_name()
  local quiz, errmsg = checkAnswer(aPlayer)

  if quiz and errmsg then return end
  print('TCL:: ~ file: init.lua ~ line 112 ~ playerName', playerName);
  local function on_close(state, player, fields)
    print('TCL:: ~ file: init.lua ~ line 114 ~ onclose', playerName, dump(fields));
    if fields.quit == minetest.FORMSPEC_SIGTIME then
      local vQuiz, vErrmsg = quizzes.getCurrent(playerName)
      if vErrmsg then
        checkAnswer(aPlayer, fields.answer, vQuiz)
      end
    else
      checkAnswer(aPlayer, fields.answer, quiz)
    end

    --   minetest.update_form(playerName, get_formspec(playerName, quiz.title, quiz.desc))
    -- elseif fields.answer and quiz.answer == fields.answer then
    --   minetest.get_form_timer(playerName).stop()
    --   minetest.chat_send_all("Cool, you are successful!")
    -- else
    --   minetest.get_form_timer(playerName).start(1)
    -- end
  end
  dialogClosed = false
  minetest.create_form(nil, playerName, get_formspec(playerName, quiz.title, quiz.desc), on_close)
  -- minetest.get_form_timer(playerName).start(1)
  return true
end

minetest.register_on_joinplayer(function(player)
  -- local playerName = player:get_player_name()
  -- local checkInterval = settings.checkInterval

  local function doCheck()
    local checkInterval = settings.checkInterval

    hudcheck(player)
    if (dialogClosed) then openQuizView(player) end

    if checkInterval > 0 then
      -- execute after checkInterval seconds
      minetest.after(checkInterval, doCheck)
    end
  end

  if (settings.checkInterval > 0) then
    minetest.after(0, doCheck)
  else
    minetest.after(0, function()
      hudcheck(player)
      openQuizView(player)
    end)
  end

end)

-- minetest.register_privilege(MOD_NAME, {
--     description = S("answer to quiz"),
--     give_to_singleplayer = false,
--     give_to_admin = false,
--     on_grant = hudcheck,
--     on_revoke = hudcheck
--   })
