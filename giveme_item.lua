local MOD_PATH = play_challenge.MOD_PATH
local S = play_challenge.get_translator

local callChatCmd = dofile(MOD_PATH.."call_chat_cmd.lua")

local function givemeItem(playerName, item)
  local name = item.id
  local modName = item.mod or "default"
  local count = item.count or 1
  local title = item.title or name
  -- local player = minetest.get_player_by_name(playerName)
  -- player:get_inventory():add_item('main', 'default:mese 1')

  local result = callChatCmd("giveme", playerName, {modName .. ":" .. name, count})
  if not result then
    minetest.chat_send_player(playerName, S("Can't get '@1'", default.get_translator(title)))
  else
    minetest.chat_send_player(playerName, S("You get the @1, count: @2.", default.get_translator(title), count))
  end
  return result
end

return givemeItem
