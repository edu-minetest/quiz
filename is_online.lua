local function isOnline(playerName)
  local players = minetest.get_connected_players()
  for _,player in ipairs(players) do
    local name = player:get_player_name()
    if (name == playerName) then
      -- print(playerName .. " is onlined")
      return true
    end
  end
end

return isOnline
