local minetest, play_challenge, yaml = minetest, play_challenge, yaml

local log = minetest.log
local S = play_challenge.get_translator
local MOD_NAME = play_challenge.MOD_NAME
local MOD_PATH = play_challenge.MOD_PATH
local settings = play_challenge.settings
local quizzes  = play_challenge.quizzes
local openQuizView = play_challenge.openQuizView

local merge = dofile(MOD_PATH .. "merge_table.lua")
local split = dofile(MOD_PATH .. "split.lua")

local function findIndexBy(list, value, getValue)
  if type(getValue) == "string" then
    local fieldName = getValue
    getValue = function(item) return item[fieldName] end
  end

  for ix, item in pairs(list) do
    if getValue(item, ix, list) == value then return ix end
  end
end

minetest.register_privilege("quiz", {
  description = S("manage to quiz"),
  give_to_singleplayer = false, --< DO NOT defaults to singleplayer
  give_to_admin = false,        --< DO NOT defaults to admin
})

minetest.register_chatcommand("answer", {
  description = S("answer the quiz"),
  privs = {
    quiz = true,
  },
  func = function(name, param)
    openQuizView(name)
    return true
  end,
})

minetest.register_chatcommand("loadQuiz", {
  description = S("(Re)load quiz config file"),
  privs = {
    quiz = true,
  },
  func = function(name, param)
    local newSettings = yaml.readConfig(MOD_NAME, "config.yml")
    if (type(newSettings) == "table") then
      merge(settings, newSettings)
      quizzes.clearAnswered()
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
    local result = yaml.writeConfig(settings, "config.yml", MOD_NAME)
    if result then
      return true, S("Quiz config file saved.")
    else
      return false, S("Quiz config file saving failed.")
    end
  end,
})

local function isInvalidQuiz(quiz)
  return not quiz.title or quiz.title == "" or not quiz.answer or quiz.answer == ""
end

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
    play_challenge.setLastLeavedTime(playerName, 0)
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
