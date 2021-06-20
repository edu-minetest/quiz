local chatCommands = minetest.registered_chatcommands

local function callChatCmd(cmdStr, playerName, params)
  local cmd = chatCommands[cmdStr]
  if cmd then
    local paramsType = type(params)
    if (params == nil or paramsType == "string") then
      return cmd.func(playerName, params)
    elseif paramsType == "table" then
      -- if paramsType ~= "table" then
      --   params = {playerName}
      -- else
      --   table.insert(params, 1, playerName)
      -- end

      params = table.concat(params, " ")
      return cmd.func(playerName, params)
    end
  else
    minetest.log("warning", "callChatCmd: No such chat command:" .. cmdStr)
  end
end

return callChatCmd
