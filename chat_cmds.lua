local minetest, quiz, yaml = minetest, quiz, yaml

-- local log = minetest.log
local S = quiz.get_translator
-- local MOD_NAME = quiz.MOD_NAME
local MOD_PATH = quiz.MOD_PATH
local settings = quiz.settings
local quizzes  = quiz.quizzes
local openQuizView = quiz.openQuizView

local merge = dofile(MOD_PATH .. "merge_table.lua")
local split = dofile(MOD_PATH .. "split.lua")

local isInvalidQuiz = quiz.isInvalidQuiz
local loadConfig = quiz.loadConfig
local saveConfig = quiz.saveConfig

local function findIndexBy(list, value, getValue)
  if type(getValue) == "string" then
    local fieldName = getValue
    getValue = function(item) return item[fieldName] end
  end

  for ix, item in pairs(list) do
    if getValue(item, ix, list) == value then return ix end
  end
end

minetest.register_privilege("noquiz", {
  description = S("skip to pop quiz"),
  give_to_singleplayer = false, --< DO NOT defaults to singleplayer
  give_to_admin = false,        --< DO NOT defaults to admin
})

minetest.register_privilege("quiz", {
  description = S("manage to quiz"),
  give_to_singleplayer = false, --< DO NOT defaults to singleplayer
  give_to_admin = false,        --< DO NOT defaults to admin
})

minetest.register_chatcommand("answer", {
  description = S("answer the quiz"),
  func = function(name, param)
    local result = openQuizView(name)
    if result ~= true then return true, S("There are currently no quizs to answer") end
    return true
  end,
})

minetest.register_chatcommand("loadQuiz", {
  description = S("(Re)load quiz config file"),
  privs = {
    quiz = true,
  },
  func = function(name, param)
    if loadConfig() then
      return true, S("Quiz config file loaded.")
    else
      return false, S("Quiz config file loading failed.")
    end
  end,
})

minetest.register_chatcommand("saveQuiz", {
  description = S("Save quiz to the config file"),
  privs = {
    quiz = true,
  },
  func = function(name, param)
    local result = saveConfig()
    if result then
      return true, S("Quiz config file saved.")
    else
      return false, S("Quiz config file saving failed.")
    end
  end,
})

local function listQuiz()
  local quizList = settings.quiz
  local result = {"", S("Quiz list"), "-------------", "ix,id,  title"}
  for ix, quiz in pairs(quizList) do
    result[#result+1] = ix .. "," .. quizzes.id(quiz) .. ",  " .. quiz.title
    result[#result+1] = S("Answer") .. ":" .. quiz.answer
  end
  return true, table.concat(result, "\n")
end

local function setQuiz(param)
  local quizList = settings.quiz
  local id, content = param:match("^([^ ]+) *(.*)$")
  local params = split.table(content)
  -- if not title or title == "" or not answer or answer == "" then
  --   return false, S("title and answer params required")
  -- end
  local ix = tonumber(id)
  if ix then
    if ix > 0 and ix <= #quizList then
      local item = quizList[ix]
      merge(item, params)
      return true, S("Quiz[@1] updated", ix)
    else
      if isInvalidQuiz(params) then
        return false, S("title and answer params required")
      end
      quizList[#quizList+1] = params
      return true, S("Quiz added")
    end
  else
    ix = findIndexBy(quizList, id, quizzes.id)
    if ix then
      local item = quizList[ix]
      merge(item, params)
      return true, S("Quiz[@1] updated", ix)
    else
      if isInvalidQuiz(params) then
        return false, S("title and answer params required")
      end
      params.id = id
      quizList[#quizList+1] = params
      return true, S("Quiz added")
    end
  end
end

local function delQuiz(param)
  local quizList = settings.quiz
  param = (type(param) == "string") and param:match("^%s*(.-)%s*$")
  if not param or param == "" then return false, S("id/index param required") end
  local n = tonumber(param)
  if n then
    if n > 0 and n <= #quizList then
      table.remove(quizList, n)
      return true, S("remove successfully")
    else
      return false, S("Invalid index value @1", n)
    end
  else
    for ix, quiz in pairs(quizList) do
      if quizzes.id(quiz) == param then
        table.remove(quizList, ix)
        return true, S("remove successfully")
      end
    end
    return false, S("Invalid id value @1", param)
  end
end

local QuizCRUD = {
  list = listQuiz,
  ls = listQuiz,
  set = setQuiz,
  add = setQuiz,
  update = setQuiz,
  del = delQuiz,
  rm = delQuiz,
  delete = delQuiz,
  reset = function(param, playerName)
    if (type(param) == "string") and param ~= "" then playerName = param end
    quiz.setLastLeavedTime(playerName, 0)
    return true, S("reset @1 successful", playerName)
  end,
  revoke = function(param, playerName)
    if (type(param) == "string") and param ~= "" then playerName = param end
    local privs = minetest.get_player_privs(playerName)
    if (privs["quiz"]) then
      privs["quiz"] = nil
      minetest.set_player_privs(playerName, privs)
      return true, "revoke quiz ok."
    end
  end,
}

minetest.register_chatcommand("quiz", {
	params = S('<list|set|del|reset|revoke> [<index|id>, title="Title", answer="Answer"]'),
  description = S("manage the quizzes"),
  privs = {
    quiz = true,
  },
  func = function(name, param)
		local action, params = string.match(param, "^([^ ]+) *(.*)$")
    local cmd = QuizCRUD[action]
    if type(cmd) == "function" then
      return cmd(params, name)
    elseif type(quiz.defaultChatCmd) == "function" then
      return quiz.defaultChatCmd(name, param)
    else
      return false, S("Invalid quiz action: @1", (action or ""))
    end
  end,
})

local function listAward()
  local awards = settings.awards
  local result = {"", S("Award list"), "-------------", "ix,title, mod:id, count"}
  for ix, award in pairs(awards) do
    local mod = award.mod or "default"
    local modS = minetest.get_translator(mod)
    local count = award.count or 1
    local title = award.title or ""
    if title and title ~= "" and modS then title = modS(title) end
    result[#result+1] = ix .. "," .. title .. ",  " .. mod .. ":" .. award.id .. ", " .. count
  end
  return true, table.concat(result, "\n")
end

local function setAward(param)
  local awards = settings.awards
  local id, content = param:match("^([^ ]+) *(.*)$")
  local params = split.table(content)
  -- if not title or title == "" or not answer or answer == "" then
  --   return false, S("title and answer params required")
  -- end
  local ix = tonumber(id)
  if ix then
    if ix > 0 and ix <= #awards then
      local item = awards[ix]
      merge(item, params)
      return true, S("Award[@1] updated", ix)
    else
      if not id or id == "" then
        return false, S("id param required")
      end
      awards[#awards+1] = params
      return true, S("Award added")
    end
  else
    ix = findIndexBy(awards, id, "id")
    if ix then
      local item = awards[ix]
      merge(item, params)
      return true, S("Award[@1] updated", ix)
    else
      if not id or id == "" then
        return false, S("id param required")
      end
      params.id = id
      awards[#awards+1] = params
      return true, S("Award added")
    end
  end
end

local function delAward(param)
  local awards = settings.awards
  param = (type(param) == "string") and param:match("^%s*(.-)%s*$")
  if not param or param == "" then return false, S("id/index param required") end
  local n = tonumber(param)
  if n then
    if n > 0 and n <= #awards then
      table.remove(awards, n)
      return true, S("remove successfully")
    else
      return false, S("Invalid index value @1", n)
    end
  else
    for ix, quiz in pairs(awards) do
      if quizzes.id(quiz) == param then
        table.remove(awards, ix)
        return true, S("remove successfully")
      end
    end
    return false, S("Invalid id value @1", param)
  end
end

local AwardCRUD = {
  list = listAward,
  ls = listAward,
  set = setAward,
  add = setAward,
  update = setAward,
  del = delAward,
  delete = delAward,
  rm = delAward,
}

minetest.register_chatcommand("quizAward", {
	params = S('<list|set|del> <Index|name> title="Title" [mod="default"] [count=<Number>]'),
  description = S("manage the awards"),
  privs = {
    quiz = true,
  },
  func = function(name, param)
		local action, params = string.match(param, "^([^ ]+) *(.*)$")
    local cmd = AwardCRUD[action]
    if type(cmd) == "function" then
      return cmd(params)
    else
      return false, S("Invalid award action: @1", (action or ""))
    end
  end,
})

local function boolParam(title, desc)
  return {
    params = '[true|false]',
    description = S("get or set @1", desc),
    privs = {
      quiz = true,
    },
    func = function(name, param)
      local value = string.match(param, "^%s*([tTfF])")
      local result
      if ((type(value) == "string") and value ~= "") then
        local n = string.lower(value) == "t"
        settings[title] = n
        result = S("@1 has been changed to @2", title, dump(n))
      else
        result = title .. ":" .. tostring(settings[title])
      end
      return true, result
    end,
  }
end

local function numerParam(title, unit, desc)
  return {
    params = '[<'.. unit .. '>]',
    description = S("get or set @1", desc),
    privs = {
      quiz = true,
    },
    func = function(name, param)
      local value = string.match(param, "(%d+)")
      local result
      if ((type(value) == "string") and value ~= "") then
        local n = tonumber(value)
        if n then
          settings[title] = n
          result = S("@1 has been changed to @2", title, n) .. " " .. unit
        else
          return false, S("Invalid param: @1", param)
        end
      else
        result = title .. ":" .. settings[title] .. " " .. unit
      end
      return true, result
    end,
  }
end

minetest.register_chatcommand("totalPlayTime",
  numerParam("totalPlayTime", S("minutes"), S("the total maximum play time")))
minetest.register_chatcommand("restTime",
  numerParam("restTime", S("minutes"), S("the rest time at least")))
minetest.register_chatcommand("idleInterval",
  numerParam("idleInterval", S("minutes"), S("the time between answering quiz")))
minetest.register_chatcommand("kickDelay",
  numerParam("kickDelay", S("seconds"), S("the delay time to kick off")))
minetest.register_chatcommand("checkInterval",
  numerParam("checkInterval", S("seconds"), S("the interval time to check quiz")))
minetest.register_chatcommand("skipAnswered",
  boolParam("skipAnswered", S("whether skip the correct answered")))
minetest.register_chatcommand("forceAdminRest",
  boolParam("forceAdminRest", S("whether force the administrator reset too")))
minetest.register_chatcommand("forceAdminQuiz",
  boolParam("forceAdminQuiz", S("whether force the administrator answer quiz too")))
minetest.register_chatcommand("immediateQuiz",
  boolParam("immediateQuiz", S("whether ask the quiz immediately after joining the game")))
