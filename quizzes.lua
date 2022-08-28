local minetest, yaml, quiz = minetest, yaml, quiz

-- Set by the mod to store and retrieve information.
-- The information is persisted, so after a server restart the information is still available.
local modstore = quiz.store
local MOD_NAME = quiz.MOD_NAME
local MOD_PATH = quiz.MOD_PATH
local S = quiz.get_translator
local settings = quiz.settings
local logQuiz = quiz.logQuiz

local toBool = dofile(MOD_PATH .. "to_bool.lua")
-- local playerAttrs = dofile(MOD_PATH .. "player_attrs.lua")
local calcType = dofile(MOD_PATH .. "calc_type.lua")
local merge = dofile(MOD_PATH .. "merge_table.lua")

-- local isArrayEqu = dofile(MOD_PATH .. "array.lua").equal
quiz.calcType = calcType

local getSession = quiz.getSession

local Quizzes = {}
-- local quizIdPrefix = MOD_NAME .. ":"

--< Current Quiz Index
-- modstore:get_int("currentQuiz")
-- local currQuiz = 1
-- if currQuiz == nil or currQuiz < 1 then currQuiz = 1 end
-- local quizzes = settings.quiz

local function isInvalidQuiz(quiz)
  return not quiz.title or quiz.title == "" or not quiz.answer or quiz.answer == ""
end
quiz.isInvalidQuiz = isInvalidQuiz

local function getLastCheckedTime(playerName)
  return getSession(playerName).lastChecked or 0
end

local function setLastCheckedTime(playerName, value)
  local session = getSession(playerName)
  if value == nil then value = os.time() end
  session.lastChecked = value
end

function Quizzes.lastChecked(playerName)
  return getLastCheckedTime(playerName)
end

function Quizzes.clearAnswered()
  local sessions = quiz.sessions
  for _,v in ipairs(sessions) do
    if v and v.lastChecked ~= nil then v.lastChecked = 0 end
  end

end

local function loadConfig(filename)
  if filename == nil then filename = "config.yml" end
  local newSettings = yaml.readConfig(MOD_NAME, filename, {"quiz"})
  local result = false
  if (type(newSettings) == "table") then
    for k,v in pairs(newSettings) do
      settings[k] = v
    end
    Quizzes.clearAnswered()
    result = true
  end
  return result
end
quiz.loadConfig = loadConfig

local function saveConfig(filename)
  if filename == nil then filename = "config.yml" end
  return yaml.writeConfig(settings, filename, MOD_NAME)
end
quiz.saveConfig = saveConfig

local function id(quiz)
  local result = quiz.id
  if result == nil then
    if quiz.type == "calc" then
      result = quiz.calc
    else
      result = minetest.sha1(quiz.title .. quiz.answer)
    end
  end
  return result
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
  -- local attrs = player:get_meta()
  local quizzes = settings.quiz
  local currQuiz = modstore:get_int(playerName .. ":currentQuiz")
  if currQuiz == 0 then currQuiz = 1 end
  if (not quizzes) then return nil, S("No any quiz defined") end
  if (currQuiz > #quizzes) then
    setCurrent(playerName, 1)
    currQuiz = 1
  end
  local quiz = quizzes[currQuiz]

  while (not quiz.title or not quiz.answer) and currQuiz < #quizzes do
    -- skip illegal quiz
    currQuiz = currQuiz + 1
    quiz = quizzes[currQuiz]
  end
  if (not quiz.title or not quiz.answer) then return nil, S("invalid quiz") end

  -- print('TCL:: ~ file: quizzes.lua ~ line 58 ~ getCurrent', currQuiz, dump(quiz));
  if (not quiz) then return nil, S("No such quiz Id: '@1'", currQuiz) end
  if settings.skipAnswered and settings.skipAnswered > 0 and quiz.type ~= "calc" then
    local index = currQuiz
    local session = getSession(playerName)
    local answered = session[id(quiz)..":answered"] or 0
    while answered >= settings.skipAnswered and index < #quizzes do
      index = index+1
      quiz = quizzes[currQuiz]
      answered = session[id(quiz)..":answered"] or 0
    end
    setCurrent(playerName, index)
    -- print('TCL:: ~ file: quizzes.lua ~ line 81 ~ getCurrent - answered', attrId, answered);
    if (answered >= settings.skipAnswered) then
      return quiz, S("@1 answered all the questions correctly.", playerName)
    end
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

local function incValue(session, key)
  local value =  session[key] or 0
  session[key] = value + 1
end

local function trim(s)
  return string.gsub(s, "^%s*(.-)%s*$", "%1") --trim spaces
end

local function check(playerName, answer, quiz)
  -- print('TCL:: ~ file: quizzes.lua ~ line 108 ~ check - playerName, answer, quiz', playerName, answer, dump(quiz));
  if not quiz and not answer then
    -- check whether it's idletime if no provide answer
    local idletime = settings.idleInterval
    if (idletime) then
      idletime = idletime * 60
      local lasttime = getLastCheckedTime(playerName)
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
  -- print('TCL:: ~ file: quizzes.lua ~ line 132 ~ check quiz', dump(quiz));
  if quiz then
    -- local attrs = player:get_meta()
    local quizId= id(quiz)
    if answer ~= nil then
      answer = trim(answer) --trim spaces
      local session = getSession(playerName)
      local vRealAnswer = quiz.answer
      local vType = quiz["type"] or type(vRealAnswer)
      if vType == "number" then
        answer = tonumber(answer)
      elseif vType == "boolean" then
        answer = toBool(answer)
      elseif vType == "calc" then
        if quiz["real_answer"] ~= nil then
          vRealAnswer = quiz["real_answer"]
        else
          vRealAnswer = calcType.execute(quiz["calc"], true)
        end
        if type(vRealAnswer) == "table" then
          vType = "string"
          vRealAnswer = "/^" .. vRealAnswer[1] .. "%.%.%.+" .. vRealAnswer[2] .. "/"
        else
          answer = tonumber(answer)
        end
      elseif vType == "select" then
        answer = table.concat(answer, ",")
        if type(vRealAnswer) == "table" then
          table.sort(vRealAnswer)
          vRealAnswer = table.concat(vRealAnswer, ",")
        elseif type(vRealAnswer) == "string" then
          local t = string.split(vRealAnswer, ",")
          for i=1, #t do
            t[i] = tonumber(trim(t[i]))
          end
          table.sort(t)
          vRealAnswer = table.concat(t, ",")
        else
          vRealAnswer = "" .. vRealAnswer
        end
      end
      local ok = false
      if vType == "string" and string.sub(vRealAnswer, 1, 1) == "/" and string.sub(vRealAnswer, -1) == "/" then
        vRealAnswer = vRealAnswer:sub(2, #vRealAnswer-1)
        ok = answer:find(vRealAnswer) ~= nil
      elseif answer == vRealAnswer then
        ok = true
      end
      logQuiz(playerName, quiz, answer, ok)
      if ok then
        if vType == "calc" then
          quiz.calc = nil
        end

        local answeredName = quizId ..":answered"
        incValue(session, answeredName)

        -- local answered = playerAttrs.getQuiz(attrs, answeredName)
        -- answered = answered + 1
        -- playerAttrs.setQuiz(attrs, answeredName, answered)

        setLastCheckedTime(playerName, os.time())
        next(playerName)
        return true
      else
        local wrongName = quizId .. ":wrong"
        incValue(session, wrongName)
        -- local wrong = playerAttrs.getQuiz(attrs, wrongName)
        -- wrong = wrong + 1
        -- playerAttrs.setQuiz(attrs, wrongName, wrong)

        return false
      end
    end
  end
  return quiz, errmsg
end

local function getTitle(quiz)
  if quiz["type"] == "calc" and quiz["calc"] == nil then
    local expr = calcType.parse(quiz.answer, quiz.forceInt)
    quiz["calc"] = expr
    quiz["real_answer"] = calcType.execute(expr, true)
  end
  local result = string.gsub(quiz.title, "$(%w+)", function (n)
    return quiz[n]
  end)
  return result
end

Quizzes.getCurrent = getCurrent
Quizzes.setCurrent = setCurrent
Quizzes.check = check
Quizzes.next = next
Quizzes.id = id
Quizzes.getTitle = getTitle

return Quizzes
