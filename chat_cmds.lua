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
      merge(settings, newSettings)
      return true, S("Quiz config file saved.")
    else
      return false, S("Quiz config file saving failed.")
    end
  end,
})
