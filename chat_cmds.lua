local log = minetest.log
local S = play_challenge.get_translator
local MOD_NAME = play_challenge.MOD_NAME
local MOD_PATH = play_challenge.MOD_PATH
local settings = play_challenge.settings
local quizzes  = play_challenge.quizzes

local merge = dofile(MOD_PATH .. "merge_table.lua")

minetest.register_chatcommand("loadQuiz", {
  description = S("(Re)load quiz config file"),
  privs = {
    server = true,
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
    server = true,
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

local QuizCRUD = {
  list = function()
    local quizList = settings.quiz
    local result = {"", S("Quiz list"), "-------------", "ix,id,  title"}
    for ix, quiz in pairs(quizList) do
      result[#result+1] = ix .. "," .. quizzes.id(quiz) .. ",  " .. quiz.title
    end
    return true, table.concat(result, "\n")
  end,
  add = function(param)
    return true, 'to do'
  end,
  del = function(param)
    local quizList = settings.quiz
    param = (type(param) == "string") and param:match("^%s*(.-)%s*$")
    if not param or param == "" then return false, S("id/index param required") end
    local n = tonumber(param)
    if n then
      if n > 0 and n < #quizList then
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
  end,
  edit = function(param)
    return true, 'to do'
  end,
}

minetest.register_chatcommand("quiz", {
	params = S("< list|add|del|edit > [< index|id >, \"< Title >\", \"< Answer >\"]"),
  description = S("manage the quizzes"),
  privs = {
    server = true,
  },
  func = function(name, param)
		local action, params = string.match(param, "^([^ ]+) *(.*)$")
    local cmd = QuizCRUD[action]
    if type(cmd) == "function" then
      return cmd(params)
    else
      return false, S("Invalid quiz action: @1", action)
    end
  end,
})
