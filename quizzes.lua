-- Set by the mod to store and retrieve information.
-- The information is persisted, so after a server restart the information is still available.
local modstore = play_challenge.store
local MOD_NAME = play_challenge.MOD_NAME
local MOD_PATH = play_challenge.MOD_PATH
local S = play_challenge.get_translator
local settings = play_challenge.settings

local toBool = dofile(MOD_PATH .. "to_bool.lua")

local Quizzes = {}
-- record player last answered time
local lastAnswered = {}
local quizIdPrefix = MOD_NAME .. ":"

--< Current Quiz Index
-- modstore:get_int("currentQuiz")
-- local currQuiz = 1
-- if currQuiz == nil or currQuiz < 1 then currQuiz = 1 end
-- local quizzes = settings.quiz

function Quizzes.lastAnswered(playerName)
  return lastAnswered[playerName]
end

local function id(quiz)
  return quiz.id or minetest.sha1(quiz.title)
end

local function getPlayerAttr(attrs, attrName, valueType)
  if not valueType then valueType = "int" end
  attrName = quizIdPrefix .. attrName
  local result = attrs["get_"..valueType](attrs, attrName)
  return result
end

local function setPlayerAttr(attrs, attrName, value, valueType)
  if not valueType then valueType = "int" end
  attrName = quizIdPrefix .. attrName
  return attrs["set_"..valueType](attrs, attrName, value)
end

local function setCurrent(playerName, index)
  local quizzes = settings.quiz
  local currQuiz = modstore:get_int(playerName .. ":currentQuiz")
  if index > #quizzes then index = #quizzes end
  if index < 1 then index = 1 end
  if index ~= currQuiz then
    currQuiz = index
    modstore:set_int(playerName ..":currentQuiz", currQuiz)
  end
end

local function getCurrent(playerName)
  local player = playerName
  if type(player) == "string" then
    player = minetest.get_player_by_name(player)
  else
    playerName = player:get_player_name()
  end
  if not player then return nil, S("@1 may be offline", playerName) end
  local attrs = player:get_meta()
  local quizzes = settings.quiz
  local currQuiz = modstore:get_int(playerName .. ":currentQuiz")
  if currQuiz == 0 then currQuiz = 1 end
  if (not quizzes) then return nil, S("No any quiz defined") end
  if (currQuiz > #quizzes) then setCurrent(playerName, 1) end
  local quiz = quizzes[currQuiz]

  while (not quiz.title or not quiz.answer) and currQuiz < #quizzes do
    -- skip illegal quiz
    currQuiz = currQuiz + 1
    quiz = quizzes[currQuiz]
  end
  if (not quiz.title or not quiz.answer) then return nil, S("invalid quiz") end

  -- print('TCL:: ~ file: quizzes.lua ~ line 58 ~ getCurrent', currQuiz, dump(quiz));
  if (not quiz) then return nil, S("No such quiz Id: '@1'", currQuiz) end
  if settings.skipAnswered then
    -- local quizId= MOD_NAME .. ":quiz:"
    local index = currQuiz
    -- local attrId= quizId .. id(quiz)
    local answered = getPlayerAttr(attrs, id(quiz)..":answered") -- attrs:get_int(attrId)
    while answered >= settings.skipAnswered and index < #quizzes do
      index = index+1
      quiz = quizzes[currQuiz]
      -- attrId= quizId .. id(quiz)
      answered = getPlayerAttr(attrs, id(quiz)..":answered")
    end
    setCurrent(playerName, index)
    -- print('TCL:: ~ file: quizzes.lua ~ line 81 ~ getCurrent - answered', attrId, answered);
    if (answered >= settings.skipAnswered) then return quiz, S("All quizzes are answered") end
  end
  return quiz
end

local function next(playerName)
  local quizzes = settings.quiz
  local currQuiz = modstore:get_int(playerName .. ":currentQuiz")
  if (currQuiz == nil) then
    currQuiz = 1
  else
    currQuiz = currQuiz + 1
    if currQuiz > #quizzes then
      currQuiz = 1
    end
  end
  setCurrent(playerName, currQuiz)
end

local function check(playerName, answer, quiz)
  -- print('TCL:: ~ file: quizzes.lua ~ line 83 ~ check - playerName, answer, quiz', playerName, answer, quiz);
  if not quiz and not answer then
    -- check whether it's idletime if no provide answer
    local idletime = settings.idleInterval
    if (idletime) then
      idletime = idletime * 60
      local lasttime = lastAnswered[playerName] or 0
      if lasttime ~= 0 then
        lasttime = os.time() - lasttime
        -- print('TCL:: ~ file: quizzes.lua ~ line 142 ~ check: lasttime', idletime, lasttime);
        if (lasttime <= idletime) then return nil end
      end
    end
  end
  local player = playerName
  if type(player) == "string" then
    player = minetest.get_player_by_name(player)
  else
    playerName = player:get_player_name()
  end
  local errmsg = nil
  if type(quiz) ~= "table" then
    quiz, errmsg = getCurrent(playerName)
  end
  -- print('TCL:: ~ file: quizzes.lua ~ line 95 ~ check quiz', dump(quiz));
  if quiz then
    local attrs = player:get_meta()
    local quizId= id(quiz)
    if (type(answer) == "string") and answer ~= "" then
      local vRealAnswer = quiz.answer
      local vType = type(vRealAnswer)
      if vType == "number" then
        answer = tonumber(answer)
      elseif vType == "boolean" then
        answer = toBool(answer)
      end
      if answer == quiz.answer then
        local answeredName = quizId ..":answered"
        local answered = getPlayerAttr(attrs, answeredName)
        answered = answered + 1
        setPlayerAttr(attrs, answeredName, answered)
        lastAnswered[playerName] = os.time()
        next(playerName)
        return true
      else
        local wrongName = quizId .. ":wrong"
        local wrong = getPlayerAttr(attrs, wrongName)
        wrong = wrong + 1
        setPlayerAttr(attrs, wrongName, wrong)
        return false
      end
    end
  end
  return quiz, errmsg
end

Quizzes.getCurrent = getCurrent
Quizzes.setCurrent = setCurrent
Quizzes.check = check
Quizzes.next = next
Quizzes.id = id

return Quizzes
