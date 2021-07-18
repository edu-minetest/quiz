local MOD_NAME = quiz.MOD_NAME
local MOD_PATH = quiz.MOD_PATH
local S = quiz.get_translator
--< in Mineclone 2 game
local isMineClone = minetest.get_modpath("mcl_core") ~= nil
local callChatCmd = dofile(MOD_PATH.."call_chat_cmd.lua")

local itemMapper

if (isMineClone) then
  itemMapper = yaml.readConfig(MOD_NAME, "mineclone_items.yml")
end

local function givemeItem(playerName, item)
  local name = item.id
  local modName = item.mod or "default"
  local count = item.count or 1
  local title = item.title or name or ""
  local T = minetest.get_translator(modName) or S
  local id = modName .. ":" .. name
  local mcItem = itemMapper and itemMapper[id]
  if mcItem then
    id = mcItem.id
    if mcItem.title then title = mcItem.title end
  end

  -- local player = minetest.get_player_by_name(playerName)
  -- player:get_inventory():add_item('main', 'default:mese 1')

  -- print("giveme Item:", modName, name, dump(item))
  local result = callChatCmd("giveme", playerName, {id, count})
  if not result then
    minetest.chat_send_player(playerName, S("Can't get '@1'", T(title)))
  else
    minetest.chat_send_player(playerName, S("You get the @1, count: @2.", T(title), count))
  end
  return result
end

return givemeItem
