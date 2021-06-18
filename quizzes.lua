-- Set by the mod to store and retrieve information.
-- The information is persisted, so after a server restart the information is still available.
local modstore = minetest.get_mod_storage()
local MOD_NAME = play_challenge.MOD_NAME
local S = play_challenge.get_translator
local settings = play_challenge.settings

local Quizzes = {}
local lastAnswered = {}

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
  local attrs = player:get_meta()
  local quizzes = settings.quiz
  local currQuiz = modstore:get_int(playerName .. ":currentQuiz")
  if currQuiz == 0 then currQuiz = 1 end
  if (not quizzes) then return nil, S("No quesion defined error") end
  if (currQuiz > #quizzes) then setCurrent(playerName, 1) end
  local quiz = quizzes[currQuiz]
  print('TCL:: ~ file: quizzes.lua ~ line 58 ~ getCurrent', currQuiz, dump(quiz));
  if (not quiz) then return nil, S("No such quesion Id: '@1' defined error", currQuiz) end
  if settings.skipAnswered then
    local quizId= MOD_NAME .. ":quiz:"
    local index = currQuiz
    local attrId= quizId .. id(quiz)
    local answered = attrs:get_int(attrId)
    while answered >= settings.skipAnswered and index < #quizzes do
      index = index+1
      quiz = quizzes[currQuiz]
      attrId= quizId .. id(quiz)
      answered = attrs:get_int(attrId)
    end
    setCurrent(playerName, index)
    if (answered >= settings.skipAnswered) then return quiz, S("All quesions are answered") end
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
  print('TCL:: ~ file: quizzes.lua ~ line 83 ~ check - playerName, answer, quiz', playerName, answer, quiz);
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
  print('TCL:: ~ file: quizzes.lua ~ line 95 ~ check quiz', dump(quiz));
  if quiz then
    local attrs = player:get_meta()
    local attrId= MOD_NAME .. ":quiz:" .. id(quiz)
    if (type(answer) == "string") then
      if answer == quiz.answer then
        local answeredName = attrId ..":answered"
        local answered = attrs:get_int(answeredName)
        answered = answered + 1
        print('TCL:: ~ file: quizzes.lua ~ line 104 ~ check answered count', answered);
        attrs:set_int(answeredName, answered)
        lastAnswered[playerName] = os.time()
        next(playerName)
        return true
      else
        local wrongName = attrId .. ":wrong"
        local wrong = attrs:get_int(wrongName)
        wrong = wrong + 1
        print('TCL:: ~ file: quizzes.lua ~ line 112 ~ check wrong count', wrong);
        attrs:set_int(wrongName, wrong)
        return false
      end
    else -- check whether it's idletime if no provide answer
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
