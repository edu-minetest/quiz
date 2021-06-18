local MOD_PATH = play_challenge.MOD_PATH

local callChatCmd = dofile(MOD_PATH.."call_chat_cmd")

local function giveItem(playerName, item, count)
  return callChatCmd("give", playerName, {item, count})
end

return giveItem
