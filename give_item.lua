local MOD_PATH = play_challenge.MOD_PATH

local callChatCmd = dofile(MOD_PATH.."call_chat_cmd.lua")

local function giveItem(playerName, item, count)
  if not count then count = 1 end
  return callChatCmd("give", playerName, {item, count})
end

return giveItem
