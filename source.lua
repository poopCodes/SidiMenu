--[[
  sidimenu is in beta version, if you find any bugs or want to add things or fix anything, please make pull request with changes, or make issue if you find a bug or join our discord
  
  - PoopsockPy: Programmer and Creator of SidiMenu/SidiCodes
  
--]]

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local function getService(name)
  local service = game:GetService(name)
  return (cloneref and cloneref(service)) or service
end

local secureMode = false
local customAssetId = nil
if getgenv then
  pcall(function() secureMode = getgenv().RAYFIELD_SECURE end)
  pcall(function() customAssetId = getgenv().RAYFIELD_ASSET_ID end)
end

local Players = getService("Players")
local RunService = getService("RunService")
local UserInputService = getService("UserInputService")
local TweenService = getService("TweenService")
local HttpService = getService("HttpService")
local ReplicatedStorage = getService("ReplicatedStorage")
local TextChatService = getService("TextChatService")
local Workspace = getService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local voiceChatInternal = nil
pcall(function()
  voiceChatInternal = cloneref(game:GetService("VoiceChatInternal"))
end)
if not voiceChatInternal then
  for _, v in ipairs(game:GetChildren()) do
    if v.ClassName == "VoiceChatInternal" then
      voiceChatInternal = cloneref(v)
      break
    end
  end
end

local getRawMetatable = getrawmetatable or getmetatable
local hookFunction = hookfunction or function(f, hook) local old; old = hookfunction(f, hook); return old end
local getGC = getgc or function() return {} end
local getInfo = getinfo or debug.getinfo

local function noopFunction(func)
  hookFunction(func, function() return nil end)
end

local unicodeMap = {
  a='a' ,b='b', c='c' ,d='d' ,e='e' ,f='f' ,g='g',
  A='A' ,b='B', c='C' ,d='D' ,e='E' ,f='F' ,g='G'
}
local function unicodeEvade(str)
  return str:gsub('.', function(c) return unicodeMap[c] or c end)
end

local function resolveIP(ip)
  local ok, res = pcall(function()
    return HttpService:JSONDecode(HttpService:GetAsync("http://ip-api.com/json/" .. ip .. "?fields=country,isp,city,lat,lon,proxy,vpn,hosting"))
  end)
  if ok and res and res.country then
    return {
      Country = res.country,
      ISP = res.isp,
      City = res.city,
      Latitude = res.lat,
      Longitude = res.lon,
      VPN = res.proxy or res.vpn or res.hosting,
      Type = (res.proxy or res.vpn or res.hosting) and "VPN/Proxy" or "Real"
    }
  end
end

local flyEnabled = false
local noclipEnabled = false
local infiniteJumpEnabled = false
local invisEnabled = false
local aimbotEnabled = false
local aimbotHead = false
local sidibotEnabled = false
local espEnabled = false
local espVersion = "ESP B2"
local espColor = Color3.fromRGB(255, 0, 0)
local sidiCheatEnabled = false
local savePlaceLoader = false
local chatBypassText = ""

local flyCon, noclipCon, aimCon, sidCon, infCon, flyGyro, flyVel
local espObjects = {}

local function StartFly()
  local char = LocalPlayer.Character
  if not char then return end
  local root = char:FindFirstChild("HumanoidRootPart")
  local hum = char:FindFirstChild("Humanoid")
  if not root or not hum then return end
  
  flyGyro = Instance.new("BodyGyro")
  flyGyro.MaxTorque = Vector3.new(400000, 400000, 400000)
  flyGyro.P = 30000
  flyGyro.Parent = root
  flyVel = Instance.new("BodyVelocity")
  flyVel.MaxForce = Vector3.new(400000, 400000, 400000)
  flyVel.Velocity = Vector3.zero
  flyVel.P = 30000
  flyVel.Parent = root
  
  hum.PlatformStand = true
  
  flyCon = RunService.Heartbeat:Connect(function()
    if not flyEnabled then return end
    local dir = Vector3.zero
    local cam = Camera.CFrame
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += cam.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= cam.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= cam.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += cam.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.yAxis end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir -= Vector3.yAxis end
    if dir.Magnitude > 0 then dir = dir.Unit * 50 end
    if flyVel and flyVel.Parent then flyVel.Velocity = dir end
    if flyGyro and flyGyro.Parent then flyGyro.CFrame = cam end
  end)
end

local function StopFly()
  flyEnabled = false
  if flyCon then flyCon:Disconnect(); flyCon = nil end
  if flyGyro then flyGyro:Destroy(); flyGyro = nil end
  if flyVel then flyVel:Destroy(); flyVel = nil end
  local char = LocalPlayer.Character
  if char then
    local hum = char:FindFirstChild("Humanoid")
    if hum then hum.PlatformStand = false end
  end
end

local function SetNoclip(state)
  noclipEnabled = state
  if state then
    noclipCon = RunService.Stepped:Connect(function()
      if not noclipEnabled or not LocalPlayer.Character then return end
      for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
        if part:IsA("BasePart") then part.CanCollide = false end
      end
    end)
  else
    if noclipCon then noclipCon:Disconnect(); noclipCon = nil end
  end
end

local function SetInvisible(state)
  invisEnabled = state
  if LocalPlayer.Character then
    for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
      if part:IsA("BasePart") then part.Transparency = state and 1 or 0 end
    end
  end
end

local function SetInfiniteJump(state)
  infiniteJumpEnabled = state
  if state then
    infCon = UserInputService.JumpRequest:Connect(function()
      if not infiniteJumpEnabled or not LocalPlayer.Character then return end
      local hum = LocalPlayer.Character:FindFirstChild("Humanoid")
      if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end)
  else
    if infCon then infCon:Disconnect(); infCon = nil end
  end
end

local function GetClosestPlayer()
  local best, bestDist = nil, 1/0
  for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LocalPlayer and p.Character then
      local root = p.Character:FindFirstChild("HumanoidRootPart")
      local head = p.Character:FindFirstChild("Head")
      if root and head and LocalPlayer.Character then
        local myRoot = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if myRoot then
          local dist = (root.Position - myRoot.Position).Magnitude
          if dist < bestDist then bestDist = dist; best = p end
        end
      end
    end
  end
  return best
end

local function StartAimbot()
  aimCon = RunService.RenderStepped:Connect(function()
    if not aimbotEnabled then return end
    local t = GetClosestPlayer()
    if t and t.Character then
      local part = aimbotHead and t.Character:FindFirstChild("Head") or t.Character:FindFirstChild("HumanoidRootPart")
      if part then
        Camera.CFrame = CFrame.new(Camera.CFrame.Position, part.Position)
      end
    end
  end)
end

local function StartSidiBot()
  sidCon = RunService.RenderStepped:Connect(function()
    if not sidibotEnabled then return end
    local t = GetClosestPlayer()
    if t and t.Character then
      local part = t.Character:FindFirstChild("HumanoidRootPart")
      if part then
        local curLook = Camera.CFrame.LookVector
        local targetLook = (part.Position - Camera.CFrame.Position).Unit
        local smoothed = curLook:Lerp(targetLook, 0.3)
        Camera.CFrame = CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + smoothed)
      end
    end
  end)
end

local function CreateESP(player, version, color)
  espRemove(player)
  local objects = {}
  local char = player.Character
  if not char then return end
  if version == "ESP S1" then
    local h = Instance.new("Highlight")
    h.FillColor = color; h.FillTransparency = 0.8; h.OutlineColor = color; h.OutlineTransparency = 0; h.Parent = char
    table.insert(objects, h)
  elseif version == "ESP B2" then
    local h = Instance.new("Highlight")
    h.FillColor = color; h.FillTransparency = 0.5; h.OutlineColor = color; h.OutlineTransparency = 0; h.Parent = char
    table.insert(objects, h)
  elseif version == "ESP T3" then
    local head = char:FindFirstChild("Head")
    if head then
      local bill = Instance.new("BillboardGui")
      bill.Size = UDim2.new(2,0,2,0); bill.AlwaysOnTop = true; bill.Parent = head
      local tri = Instance.new("ImageLabel")
      tri.Size = UDim2.new(1,0,1,0); tri.BackgroundTransparency = 1; tri.Image = "rbxassetid://0"; tri.ImageColor3 = color; tri.Parent = bill
      table.insert(objects, bill)
    end
  end
  espObjects[player.UserId] = objects
end

local function espRemove(player)
  if espObjects[player.UserId] then
    for _, obj in ipairs(espObjects[player.UserId]) do pcall(function() obj:Destroy() end) end
    espObjects[player.UserId] = nil
  end
end

local function refreshESP()
  for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then
      espRemove(p)
      if espEnabled then createESP(p, espVersion, espColor) end
    end
  end
end

local function HookChatFilter()
  pcall(function()
    local textChatService = TextChatService
    for _, obj in ipairs(getGC()) do
      if type(obj) == "function" and getInfo(obj).name == "FilterStringAsync" then
        local old = obj
        hookFunction(obj, function(self, text, ...)
          if sidiCheatEnabled then
            return {GetChatForUserAsync = function() return text end, Source = text}
          end
          return old(self, text, ...)
        end)
        break
      end
    end
  end)
end

local function SendBypassedMessage(msg)
  local bypassed = unicodeEvade(msg)
  pcall(function()
    local remote = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
    if remote then
      local say = remote:FindFirstChild("SayMessageRequest")
      if say and say:IsA("RemoteEvent") then say:FireServer(bypassed, "All") return end
    end
  end)
  pcall(function()
    local channel = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
    if channel then channel:SendAsync(bypassed) end
  end)
end

local function GrabIP()
  local ips = {}
  if voiceChatInternal then
    pcall(function()
      local activePeers = voiceChatInternal.ActivePeers
      if activePeers then
        for _, peer in ipairs(activePeers) do
          local mt = getRawMetatable(peer)
          if mt and mt.__index and mt.__index.ProcessICECandidate then
            local oldProcess = mt.__index.ProcessICECandidate
            hookFunction(oldProcess, function(self, iceCandidate)
              if iceCandidate and type(iceCandidate) == "string" then
                for ipStr in iceCandidate:gmatch("(%d+%.%d+%.%d+%.%d+)") do
                  local a,b,c,d = ipStr:match("(%d+)%.(%d+)%.(%d+)%.(%d+)")
                  a, b, c, d = tonumber(a), tonumber(b), tonumber(c), tonumber(d)
                  if a and a~=10 and a~=127 and not (a==192 and b==168) and not (a==172 and b>=16 and b<=31) then
                    if not table.find(ips, ipStr) then ips[#ips+1] = ipStr end
                  end
                end
              end
              return oldProcess(self, iceCandidate)
            end)
          end
        end
      end
    end)
  end
  return ips
end

local function EnableSidiCheat()
  sidiCheatEnabled = true
  pcall(function()
    local oldKick = LocalPlayer.Kick
    hookFunction(LocalPlayer.Kick, function(...) if sidiCheatEnabled then return end; return oldKick(...) end)
  end)
  for _, f in ipairs(getGC()) do
    if type(f) == "function" and getInfo(f).name == "kick" then noopFunction(f) end
  end
  HookChatFilter()
end

local Window = Rayfield:CreateWindow({
   Name = "SidiMenu V1",
   Icon = 0, -- Icon in Topbar. Can use Lucide Icons (string) or Roblox Image (number). 0 to use no icon (default).
   LoadingTitle = "Loading SidiMenu....",
   LoadingSubtitle = "by SidiCodes",
   ShowText = "SidiMenu", -- for mobile users to unhide Rayfield, change if you'd like
   Theme = "Default", -- Check https://docs.sirius.menu/rayfield/configuration/themes

   ToggleUIKeybind = "", -- The keybind to toggle the UI visibility (string like "K" or Enum.KeyCode)

   DisableRayfieldPrompts = false,
   DisableBuildWarnings = false, -- Prevents Rayfield from emitting warnings when the script has a version mismatch with the interface.

   -- ScriptID = "sid_xxxxxxxxxxxx", -- Your Script ID from developer.sirius.menu — enables analytics, managed keys, and script hosting

   ConfigurationSaving = {
      Enabled = true,
      FolderName = nil, -- Create a custom folder for your hub/game
      FileName = "SidiMenuSaver"
   },

   Discord = {
      Enabled = false, -- Prompt the user to join your Discord server if their executor supports it
      Invite = "sidi", -- The Discord invite code, do not include Discord.gg/. E.g. Discord.gg/ABCD would be ABCD
      RememberJoins = true -- Set this to false to make them join the Discord every time they load it up
   },

   KeySystem = false, -- Set this to true to use our key system
   KeySettings = {
      Title = "Untitled",
      Subtitle = "Key System",
      Note = "No method of obtaining the key is provided", -- Use this to tell the user how to get a key
      FileName = "Key", -- It is recommended to use something unique, as other scripts using Rayfield may overwrite your key file
      SaveKey = true, -- The user's key will be saved, but if you change the key, they will be unable to use your script
      GrabKeyFromSite = false, -- If this is true, set Key below to the RAW site you would like Rayfield to get the key from
      Key = {"Hello"} -- List of keys that the system will accept, can be RAW file links (pastebin, github, etc.) or simple strings ("hello", "key22")
   }
})

Rayfield:Notify({
   Title = "SidiMenu",
   Content = "Welcome to SidiMenu V1 (Beta Version), Report bugs or suggest ideas or command on our discord server",
   Duration = 6.5,
   Image = 4483362458,
})

local MainTab = Window:CreateTab("Main", 0)
local MovementSection = MainTab:CreateSection("Movement")
local Fly = MainTab:CreateToggle({
   Name = "Fly",
   CurrentValue = false,
   Flag = "Fly",
   Callback = function(v) flyEnabled = v; if v then StartFly() else StopFly() end end
})
local Speed = MainTab:CreateInput({
   Name = "Speed",
   CurrentValue = "16",
   PlaceholderText = "Default is 16",
   RemoveTextAfterFocusLost = false,
   Flag = "Speed",
   Callback = function(t) local s = tonumber(t); if s and LocalPlayer.Character then local hum = LocalPlayer.Character:FindFirstChild("Humanoid") if hum then hum.WalkSpeed = s end end end,
   -- The function that takes place when the input is changed
   -- The variable (Text) is a string for the value in the text box
})
local Noclip = MainTab:CreateToggle({
   Name = "Noclip",
   CurrentValue = false,
   Flag = "Noclip",
   Callback = setNoclip
})

local function playerNames()
  local n = {}
  for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then n[#n+1] = p.Name end
  end
  return #n > 0 and n or {"No Players"}
end
local teleportDropdown = MainTab:CreateDropdown({
   Name = "Teleport",
   Options = playerNames(),
   CurrentOption = {"No Players"},
   MultipleOptions = false,
   Flag = "Flag", 
   Callback = function(o)
     local t = o[1]
     if t and t ~= "No Players" then
       local tp = Players:FindFirstChild(t)
       if tp and tp.Character then
         local tr = tp.Character:FindFirstChild("HumanoidRootPart")
         local lr = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
         if tr and lr then
           lr.CFrame = tr.CFrame + Vector3.new(0, 2, 0)
         end
       end
     end
   end,
})
Players.PlayerAdded:Connect(function() if teleportDropdown then teleportDropdown:Refresh(playerNames()) end end)
Players.PlayerRemoving:Connect(function() task.wait(0.1); if teleportDropdown then teleportDropdown:Refresh(playerNames()) end end)

local Invisible = MainTab:CreateToggle({
   Name = "Invisible",
   CurrentValue = false,
   Flag = "Invisible",
   Callback = setInvisible
})
local InfiniteJump = MainTab:CreateToggle({
   Name = "Infinite Jump",
   CurrentValue = false,
   Flag = "InfJUMP",
   Callback = setInfiniteJump
})

local AimbotTab = Window:CreateTab("Aimbot", 442424242)
local AimbotSection = AimbotTab:CreateSection("Main Aimbot")

local EnableAimbot = AimbotTab:CreateToggle({
   Name = "Enable Aimbot",
   CurrentValue = false,
   Flag = "Aimbot",
   Callback = function(v)
     sidibotEnabled = v
     if v then StartAimbot() else if aimCon then aimCon:Disconnect(); aimCon = nil end end
   end,
})
local AimbotHead = AimbotTab:CreateToggle({
   Name = "Aimbot in Head",
   CurrentValue = false,
   Flag = "AimbotHead",
   Callback = function(v)
     aimbotHead = v
     if v then StartAimbot() else if aimCon then aimCon:Disconnect(); aimCon = nil end end
   end,
})
local AimbotSidi = AimbotTab:CreateSection("SidiBot")
local SidiBotToggle = MainTab:CreateToggle({
   Name = "SidiBot V1 Mode",
   CurrentValue = false,
   Flag = "SidiBot",
   Callback = function(v)
     sidibotEnabled = v
     if v then StartSidiBot() else if sidCon then sidCon:Disconnect(); sidCon = nil end end
   end,
})

local ESPTab = Window:CreateTab("ESP", 0)
local ESPSection = ESPTab:CreateSection("Settings")
local ESPVersion = ESPTab:CreateDropdown({
   Name = "ESP Version",
   Options = {"ESP S1", "ESP B2", "ESP T3"},
   CurrentOption = {"ESP B2"},
   MultipleOptions = false,
   Flag = "ESPVersions", -- A flag is the identifier for the configuration file; make sure every element has a different flag if you're using configuration saving to ensure no overlaps
   Callback = function(o) espVersion = o[1]; refreshESP() end,
})
local function espPlayerOpts()
  local n = {"All Players"}
  for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then n[#n+1] = p.Name end
  end
  return n
end
local espPlayerDropdown = ESPTab:CreateDropdown({
   Name = "ESP Player",
   Options = espPlayerOpts(),
   CurrentOption = {"All Players"},
   MultipleOptions = true,
   Flag = "ESPPlayer", -- A flag is the identifier for the configuration file; make sure every element has a different flag if you're using configuration saving to ensure no overlaps
   Callback = function() end,
   -- The function that takes place when the selected option is changed
   -- The variable (Options) is a table of strings for the current selected options
})
Players.PlayerAdded:Conect(function() if espPlayerDropdown then espPlayerDropdown:Refresh(espPlayerOpts()) end end)
Players.PlayerRemoving:Connect(function() task.wait(0.1); if espPlayerDropdown then espPlayerDropdown:Refresh(espPlayerOpts()) end end)
local ESPColor = ESPTab:CreateColorPicker({
    Name = "ESP Color",
    Color = espColor,
    Flag = "ESPColors", -- A flag is the identifier for the configuration file; make sure every element has a different flag if you're using configuration saving to ensure no overlaps
    Callback = function(c) espColor = c; refreshESP()
        -- The function that takes place every time the color picker is moved/changed
        -- The variable (Value) is a Color3fromRGB value based on which color is selected
    end,
})
local EnableESP = ESPTab:CreateToggle({
   Name = "Enable ESP",
   CurrentValue = false,
   Flag = "ESPEnable",
   Callback = function(v) espEnabled = v; refreshESP()
   end,
})
local ESPTeam = ESPTab:CreateSection("ESP Team")
local TeamName = ESPTab:CreateInput({
   Name = "Team Name",
   CurrentValue = "",
   PlaceholderText = "Enter team name",
   RemoveTextAfterFocusLost = false,
   Flag = "Team Name",
   Callback = function()
   -- The function that takes place when the input is changed
   -- The variable (Text) is a string for the value in the text box
   end,
})
local ESPTeamColor = ESPTab:CreateColorPicker({
    Name = "ESP Team Color",
    Color = Color3.fromRGB(0, 255, 0),
    Flag = "ESPTeamColors", -- A flag is the identifier for the configuration file; make sure every element has a different flag if you're using configuration saving to ensure no overlaps
    Callback = function()
        -- The function that takes place every time the color picker is moved/changed
        -- The variable (Value) is a Color3fromRGB value based on which color is selected
    end,
})
local EnableTeamESP = ESPTab:CreateToggle({
   Name = "Enable ESP Team",
   CurrentValue = false,
   Flag = "ESPTeamEnable",
   Callback = function()
   end,
})
local ESPSizes = ESPTab:CreateSection("ESP S1 Size Customizer")
local SizeX = ESPTab:CreateSlider({
   Name = "Size X",
   Range = {50, 300},
   Increment = 1,
   Suffix = "px",
   CurrentValue = 100,
   Flag = "SizeXESP", -- A flag is the identifier for the configuration file; make sure every element has a different flag if you're using configuration saving to ensure no overlaps
   Callback = function()
   -- The function that takes place when the slider changes
   -- The variable (Value) is a number that correlates to the value the slider is currently at
   end,
})
local SizeY = ESPTab:CreateSlider({
   Name = "Size Y",
   Range = {50, 300},
   Increment = 1,
   Suffix = "px",
   CurrentValue = 100,
   Flag = "SizeYESP", -- A flag is the identifier for the configuration file; make sure every element has a different flag if you're using configuration saving to ensure no overlaps
   Callback = function()
   -- The function that takes place when the slider changes
   -- The variable (Value) is a number that correlates to the value the slider is currently at
   end,
})
local AntiDetectionESP = ESPTab:CreateSection("Anti-Detection")
local SidiESP = ESPTab:CreateToggle({
   Name = "SidiESP V1 Mode",
   CurrentValue = false,
   Flag = "SidiESP",
   Callback = function(v)
     if v then
       Rayfield:Notify({
          Title = "SidiESP V1",
          Content = "SidiESP is enabled, SidiESP is a mode that hides the ESP From Screen Shares like discord, instagram and more... you're the only one who can see the esp, but screen shares with people nope",
          Duration = 12,
          Image = 4483362458,
       })
     end
   end,
})

local BypassTab = Window:CreateTab("Bypasses", 0)
local BypassAnti = BypassTab:CreateSection("Anti-Cheat")
local SidiCheat = BypassTab:CreateToggle({
   Name = "SidiCheat V1 Mode",
   CurrentValue = false,
   Flag = "SidiCheat",
   Callback = function(v)
     if v then
       EnableSidiCheat()
     end
   end,
})
local BypassFilter = BypassTab:CreateSection("Chat Filter")
local TextToSend = BypassTab:CreateInput({
   Name = "Text To Send",
   CurrentValue = "",
   PlaceholderText = "Enter Message",
   RemoveTextAfterFocusLost = false,
   Flag = "ChatMessage",
   Callback = function(t)
     chatBypassText = t
   end,
})
local SendMessage = BypassTab:CreateButton({
   Name = "Send",
   Callback = function()
     if chatBypassText ~= "" then
       SendBypassedMessage(chatBypassText)
     end
   end,
})
local DisableFilter = BypassTab:CreateButton({
   Name = "Disable Local Chat Filter",
   Callback = HookChatFilter,
})
local VC = BypassTab:CreateSection("Voice Chat")
local VCBan = BypassTab:CreateButton({
   Name = "Bypass Voice Chat Ban",
   Callback = function()
     pcall(function() if voiceChatInternal and voiceChatInternal.RejoinChannels then
       voiceChatInternal:RejoinChannels()
       end
     end)
   end,
})

local GrabTab = Window:CreateTab("Grabber", 0)
local ConsoleTab = Window:CreateTab("Grabber Console", 0)
local IPGrab = GrabTab:CreateSection("IP Grabber")
local GrabPlayerIP = GrabTab:CreateButton({
   Name = "Grab Player IP (via voice chat)",
   Callback = function()
     local ips = GrabIP()
     if #ips == 0 then
       local NoIP = ConsoleTab:CreateParagraph({Title = "No IPs", Content = "No IPs Found, Voice Chat Required"})
       return
     end
     for _, ip in ipairs(ips) do
       local info = resolveIP(ip)
       local content = info and string.format("IP: %s\nCountry: %s\nISP: %s\nCity: %s\nLat/Lon: %.4f, %.4f\nType: %s", ip, info.Country, info.ISP, info.City, info.Latitude, info.Longitude, info.Type) or ("IP: "..ip.."\nDetails: unresolvable")
       local PlayerIP = ConsoleTab:CreateParagraph({Title = "Player IP", Content = content})
     end
     Rayfield:Notify({
        Title = "IP Grabber",
        Content = "Done",
        Duration = 4,
        Image = 4483362458,
      })
   end,
})
local GrabInfo = ConsoleTab:CreateParagraph({Title = "Info", Content = "Uses WebRTC ICE Candidate leak, Only Works with Voice Chat Enabled"})

local AboutTab = Window:CreateTab("About", 0)
local AboutSidi = AboutTab:CreateSection("SidiMenu")
local AboutParagraph15463 = AboutTab:CreateParagraph({Title = "SidiMenu", Content = "SidiMenu Created by SidiCodes, we spent weeks of searching and programming the first version of sidimenu, please don't forgot to share that exploit and if you found bugs or suggesting new thing or command, contact us in discord"})
local AboutToS = AboutTab:CreateSection("ToS")
local AboutToSParagraph = AboutTab:CreateParagraph({Title = "Terms of Service", Content = "We are not responsible for account bans, use sidimenu at your own risk, also by enabling Enable Save Place Loader, you gonna allow sidimenu to save all games you have joined while running sidimenu to load your settings automaticliy"})
local SavePlaceLoader = AboutTab:CreateToggle({
   Name = "Enable Save Place Loader",
   CurrentValue = false,
   Flag = "SavePlaceLoader", -- A flag is the identifier for the configuration file; make sure every element has a different flag if you're using configuration saving to ensure no overlaps
   Callback = function(v)
     if v then
       Rayfield:LoadConfiguration()
     end
   end,
})
local Community = AboutTab:CreateSection("Community")
local Discord = AboutTab:CreateButton({
   Name = "Copy Discord Server Link",
   Callback = function()
     pcall(function() setclipboard("discord.gg/sidi") 
     end)
   end,
})
local Github = AboutTab:CreateButton({
   Name = "Copy Github Repository Link",
   Callback = function()
     pcall(function() setclipboard("https://github.com/SidiCodes/SidiMenu") 
     end)
   end,
})
local AboutParagraph1 = AboutTab:CreateParagraph({Title = "Version", Content = "v1.0.0"})

Rayfield:LoadConfiguration()
Rayfield:Notify({
   Title = "SidiMenu",
   Content = "Loaded Successfully...",
   Duration = 3.5,
   Image = 4483362458,
})

Players.PlayerAdded:Connect(function(p)
  task.wait(1)
  if espEnabled and p ~= LocalPlayer then createESP(p, espVersion, espColor) end
end)
Players.PlayerRemoving:Connect(espRemove)
LocalPlayer.CharacterAdded:Connect(function()
  task.wait(0.5)
  if invisEnabled then
    SetInvisible(true)
  end
  if flyEnabled then
    StopFly(); flyEnabled = true; StartFly() end
end)
