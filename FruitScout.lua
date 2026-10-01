-- KARMA v9. Paste this entire file into the executor editor.
-- Hide/reopen with the floating KARMA button. Drag the title or floating button.
-- Scans loaded fruit candidates. Auto hop starts only when you tap its button.
-- The bundled source is compiled locally; there are no remote code downloads.
local player = game:GetService("Players").LocalPlayer
while not player do task.wait(); player = game:GetService("Players").LocalPlayer end
local parent = player:WaitForChild("PlayerGui")
local previous = parent:FindFirstChild("FruitScoutBoot")
if previous then previous:Destroy() end
local boot = Instance.new("ScreenGui")
boot.Name = "FruitScoutBoot"
boot.ResetOnSpawn = false
boot.DisplayOrder = 1001
boot.Parent = parent
local message = Instance.new("TextLabel")
message.Size = UDim2.fromOffset(290, 90)
message.Position = UDim2.fromOffset(12, 45)
message.BackgroundColor3 = Color3.fromRGB(22, 26, 36)
message.TextColor3 = Color3.new(1, 1, 1)
message.TextWrapped = true
message.TextSize = 16
message.Text = "KARMA: code started. Loading panel..."
message.Parent = boot
local SOURCE = [====[
local SOURCE, RESUMED = ...
local Players = game:GetService("Players")
local player = Players.LocalPlayer
while not player do task.wait(); player = Players.LocalPlayer end
local parent = player:WaitForChild("PlayerGui")
local env = type(getgenv) == "function" and getgenv() or _G
if env.FruitScoutClose then pcall(env.FruitScoutClose) end
local boot = parent:FindFirstChild("FruitScoutBoot")
if boot then boot:Destroy() end

local function create(class, props, target)
    local obj = Instance.new(class)
    for key, value in pairs(props) do obj[key] = value end
    obj.Parent = target
    return obj
end
-- Self-contained KARMA interface; no external UI library is executed.
local theme={background=Color3.fromRGB(18,18,23),surface=Color3.fromRGB(29,29,36),
    muted=Color3.fromRGB(153,153,168),text=Color3.fromRGB(240,240,246),accent=Color3.fromRGB(221,53,74)}
local stopped, busy, auto, version = false, false, false, 0
local connections, markers, fruitRows = {}, {}, {}
local saveView = function() end
local gui = create("ScreenGui", {Name="FruitScout", ResetOnSpawn=false, DisplayOrder=1000}, parent)
local panel = create("Frame", {Name="ScoutWindow", Active=true, Visible=true,
    Size=UDim2.fromOffset(540,390), Position=UDim2.fromOffset(12,54),
    BackgroundColor3=theme.background, BorderSizePixel=0, ClipsDescendants=true}, gui)
create("UICorner", {CornerRadius=UDim.new(0,12)}, panel)
create("UIStroke", {Color=Color3.fromRGB(55,41,49),Thickness=1}, panel)
local scale = create("UIScale", {Scale=1}, panel)
local function text(value,y,h,size,target)
    return create("TextLabel", {Text=value,Position=UDim2.fromOffset(12,y),Size=UDim2.new(1,-24,0,h),
        BackgroundTransparency=1,TextColor3=theme.text,TextSize=size or 13,Font=Enum.Font.Gotham,
        TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top},target or panel)
end
local titleBar=text("KARMA",13,29,22)
titleBar.Name="DragHandle"
titleBar.Font=Enum.Font.GothamBold
titleBar.TextColor3=theme.accent
titleBar.Active=true
titleBar.Size=UDim2.new(1,-100,0,38)
local subtitle=text("BLOX FRUITS  /  v9",43,16,10)
subtitle.TextColor3=theme.muted
local status=text("Preparing scanner...",0,37,11)
status.Name="KarmaStatus"
status.Position=UDim2.new(0,12,1,-43)
status.TextColor3=theme.muted
local sidebar=create("ScrollingFrame",{Name="KarmaSidebar",Position=UDim2.fromOffset(8,72),
    Size=UDim2.new(0,104,1,-124),BackgroundTransparency=1,BorderSizePixel=0,
    CanvasSize=UDim2.fromOffset(0,230),ScrollBarThickness=2,ScrollBarImageColor3=theme.accent,
    ScrollingDirection=Enum.ScrollingDirection.Y},panel)
local pages,tabButtons={},{}
local activeTab="Fruits"
for i,name in ipairs({"Fruits","Chests","Factory","Servers","Player"}) do
    local page=create("ScrollingFrame",{Name="KarmaPage"..name,Position=UDim2.fromOffset(120,72),
        Size=UDim2.new(1,-132,1,-124),BackgroundTransparency=1,BorderSizePixel=0,
        CanvasSize=UDim2.fromOffset(0,name=="Fruits" and 390 or 330),ScrollBarThickness=3,
        ScrollBarImageColor3=theme.accent,ScrollingDirection=Enum.ScrollingDirection.Y,Visible=false},panel)
    pages[name]=page
    local tabButton=create("TextButton",{Name="KarmaTab"..name,Text=name,Position=UDim2.fromOffset(0,(i-1)*46),
        Size=UDim2.new(1,0,0,40),BackgroundColor3=theme.surface,BorderSizePixel=0,
        TextColor3=theme.muted,TextSize=13,Font=Enum.Font.GothamBold},sidebar)
    create("UICorner",{CornerRadius=UDim.new(0,7)},tabButton)
    tabButtons[name]=tabButton
    local heading=text(name:upper(),0,26,13,page)
    heading.Font=Enum.Font.GothamBold
end
local function selectTab(name)
    if not pages[name] then return end
    activeTab=name
    for key,page in pairs(pages) do
        page.Visible=key==name
        tabButtons[key].BackgroundColor3=key==name and theme.accent or theme.surface
        tabButtons[key].TextColor3=key==name and theme.text or theme.muted
    end
    saveView()
end
for name,tabButton in pairs(tabButtons) do
    table.insert(connections,tabButton.Activated:Connect(function() selectTab(name) end))
end
selectTab("Fruits")
local function button(value,y,target)
    local control=create("TextButton",{Text=value,Position=UDim2.fromOffset(8,y),Size=UDim2.new(1,-20,0,40),
        BackgroundColor3=theme.surface,TextColor3=theme.text,TextSize=13,TextWrapped=true,
        BorderSizePixel=0,Font=Enum.Font.Gotham},target)
    create("UICorner",{CornerRadius=UDim.new(0,7)},control)
    return control
end
local list=create("ScrollingFrame",{Name="FruitList",Position=UDim2.fromOffset(8,38),
    Size=UDim2.new(1,-20,0,130),BackgroundColor3=theme.surface,BorderSizePixel=0,
    ScrollBarThickness=3,ScrollBarImageColor3=theme.accent,CanvasSize=UDim2.fromOffset(0,0),
    ScrollingDirection=Enum.ScrollingDirection.Y},pages.Fruits)
create("UICorner",{CornerRadius=UDim.new(0,7)},list)
local emptyList=text("No loaded fruit candidates found.",12,58,13,list)
emptyList.Name="EmptyFruitList"
local fruitButton=button("Teleport to fruit",180,pages.Fruits)
local storeButton=button("Auto store: OFF",230,pages.Fruits)
local storeStatus=text("Select a fruit above. Storage is optional.",284,80,12,pages.Fruits)
storeStatus.Name="StorageStatus"
storeStatus.TextColor3=theme.muted
local chestButton=button("Tween to chest",38,pages.Chests)
local collectButton=button("Auto chest: OFF",88,pages.Chests)
local speedButton=button("Speed: 120",138,pages.Chests)
local stopMoveButton=button("Stop travel",188,pages.Chests)
stopMoveButton.TextColor3=theme.accent
text("Loaded chests only. Stop travel cancels collection; hiding keeps it running.",245,76,12,pages.Chests).TextColor3=theme.muted
local factoryStatus=text("Factory: checking sea...",40,88,14,pages.Factory)
factoryStatus.Name="FactoryStatus"
local syncFactoryButton=button("Factory ended now: sync timer",140,pages.Factory)
text("Timers are saved per server for this session. Sync only after a raid ends. New servers need an observed event.",202,114,12,pages.Factory).TextColor3=theme.muted
local details=text("",38,60,12,pages.Servers)
details.TextColor3=theme.muted
local autoButton=button("Auto hop: OFF",108,pages.Servers)
local hopButton=button("Hop once",158,pages.Servers)
local scanButton=button("Scan now",208,pages.Servers)
text("Hopping pauses while travelling or carrying an unstored fruit.",262,60,12,pages.Servers).TextColor3=theme.muted
local antiStunButton=button("Anti stun: OFF",38,pages.Player)
local antiStunStatus=text("Off. Enable to try local stun recovery.",98,92,13,pages.Player)
antiStunStatus.Name="AntiStunStatus"
text("Experimental: needs a locally exposed stun flag. Server-enforced stuns may remain. Hiding KARMA keeps the toggle running.",206,112,12,pages.Player).TextColor3=theme.muted
local closeButton=button("Hide",12,panel)
closeButton.Size=UDim2.fromOffset(54,34)
closeButton.Position=UDim2.new(1,-66,0,14)
local launcher=create("TextButton",{Name="ScoutToggle",Text="Hide KARMA",Active=true,
    Size=UDim2.fromOffset(124,36),Position=UDim2.fromOffset(12,8),BackgroundColor3=theme.accent,
    TextColor3=theme.text,TextSize=13,Font=Enum.Font.GothamBold,BorderSizePixel=0},gui)
create("UICorner",{CornerRadius=UDim.new(0,10)},launcher)
local clampUI=function() end
local function fitPhone()
    local camera=workspace.CurrentCamera
    if camera then
        local size=camera.ViewportSize
        scale.Scale=math.max(0.4,math.min(1,(size.X-24)/320,(size.Y-80)/240))
        local width=math.min(540,math.max(320,(size.X-24)/scale.Scale))
        panel.Size=UDim2.fromOffset(width,math.min(390,math.max(240,(size.Y-80)/scale.Scale)))
        local side=width<420 and 80 or 104
        sidebar.Size=UDim2.new(0,side,1,-124)
        for _,page in pairs(pages) do
            page.Position=UDim2.fromOffset(side+16,72)
            page.Size=UDim2.new(1,-side-28,1,-124)
        end
    end
    clampUI()
end
fitPhone()
local function moveInside(target,x,y)
    local bounds, size = gui.AbsoluteSize, target.AbsoluteSize
    if bounds.X<=0 or bounds.Y<=0 then return end
    local maxX=math.max(0,bounds.X-size.X)
    local maxY=math.max(0,bounds.Y-size.Y)
    target.Position=UDim2.fromOffset(math.max(0,math.min(x,maxX)),math.max(0,math.min(y,maxY)))
end
clampUI = function()
    for _,target in ipairs({panel,launcher}) do
        moveInside(target,target.Position.X.Offset,target.Position.Y.Offset)
    end
end
local function setVisible(value)
    panel.Visible=value
    launcher.Text=value and "Hide KARMA" or "Open KARMA"
    saveView()
end
local Input=game:GetService("UserInputService")
local function makeDraggable(target,handle)
    local held, anchor, startX, startY, moved = nil,nil,0,0,false
    local ignoreTapUntil=-1
    table.insert(connections,handle.InputBegan:Connect(function(input)
        if held or stopped then return end
        if input.UserInputType~=Enum.UserInputType.Touch
            and input.UserInputType~=Enum.UserInputType.MouseButton1 then return end
        held=input
        anchor=input.Position
        startX=target.Position.X.Offset
        startY=target.Position.Y.Offset
        moved=false
    end))
    table.insert(connections,Input.InputChanged:Connect(function(input)
        if not held or stopped then return end
        local matching=input==held or (held.UserInputType==Enum.UserInputType.MouseButton1
            and input.UserInputType==Enum.UserInputType.MouseMovement)
        if not matching then return end
        local dx,dy=input.Position.X-anchor.X,input.Position.Y-anchor.Y
        if not moved and dx*dx+dy*dy<64 then return end
        moved=true
        ignoreTapUntil=os.clock()+0.3
        moveInside(target,startX+dx,startY+dy)
    end))
    table.insert(connections,Input.InputEnded:Connect(function(input)
        if input~=held then return end
        held=nil
        if moved then ignoreTapUntil=os.clock()+0.3; saveView() end
    end))
    table.insert(connections,Input.WindowFocusReleased:Connect(function()
        if held then
            held=nil
            if moved then ignoreTapUntil=os.clock()+0.3; saveView() end
        end
    end))
    return function() return (held~=nil and moved) or os.clock()<ignoreTapUntil end
end
makeDraggable(panel,titleBar)
local launcherWasDragged=makeDraggable(launcher,launcher)
table.insert(connections,launcher.Activated:Connect(function()
    if not launcherWasDragged() then setVisible(not panel.Visible) end
end))
local closeAction = function()
    stopped = true
    for _, c in ipairs(connections) do c:Disconnect() end
    for _, row in pairs(fruitRows) do row.connection:Disconnect() end
    gui:Destroy()
end
env.FruitScoutClose = function() closeAction() end
table.insert(connections, closeButton.Activated:Connect(function() setVisible(false) end))

local function showError(err)
    auto = false
    version = version + 1
    autoButton.Text = "Auto hop: OFF"
    status.Text = "Error: " .. tostring(err):sub(1,180)
    warn("KARMA: " .. tostring(err))
end

local function setup()
    local Http = game:GetService("HttpService")
    local TP = game:GetService("TeleportService")
    local requestFn = request or http_request or (http and http.request) or (syn and syn.request)
    local queueFn = queue_on_teleport or queueonteleport or (syn and syn.queue_on_teleport)
    local key = "FruitScout2_" .. tostring(game.PlaceId)
    local function save(suffix, value)
        return pcall(function() TP:SetTeleportSetting(key .. suffix, value) end)
    end
    local function read(suffix)
        local ok, value = pcall(function() return TP:GetTeleportSetting(key .. suffix) end)
        if ok then return value end
    end
    saveView=function()
        save("View",Http:JSONEncode({visible=panel.Visible,
            x=panel.Position.X.Offset,y=panel.Position.Y.Offset,
            buttonX=launcher.Position.X.Offset,buttonY=launcher.Position.Y.Offset,tab=activeTab}))
    end
    local storedView=read("View")
    if type(storedView)=="string" then
        local ok,view=pcall(function() return Http:JSONDecode(storedView) end)
        if ok and type(view)=="table" then
            local function numberOr(value,fallback)
                if type(value)=="number" and value==value and math.abs(value)<100000 then return value end
                return fallback
            end
            panel.Position=UDim2.fromOffset(numberOr(view.x,12),numberOr(view.y,54))
            launcher.Position=UDim2.fromOffset(numberOr(view.buttonX,12),numberOr(view.buttonY,8))
            selectTab(view.tab or "Fruits")
            setVisible(view.visible~=false)
        end
    end
    fitPhone()
    local resumeAuto = RESUMED and read("Auto") == true
    local canPersist = save("Running", true)
    local canRequest = type(requestFn) == "function"
    local canResume = type(queueFn) == "function" and canPersist and type(SOURCE) == "string"
    local queued, scans, nextHop, message = false, 0, os.clock()+40, "Scanning this server"
    local retryAfter, lastTeamAttempt = 0, 0
    env.FruitScoutVisited = env.FruitScoutVisited or {}
    local visited = env.FruitScoutVisited[key] or {}
    env.FruitScoutVisited[key] = visited
    local saved = read("Visited")
    if type(saved) == "string" then
        local ok, decoded = pcall(function() return Http:JSONDecode(saved) end)
        if ok and type(decoded) == "table" then
            for id, at in pairs(decoded) do
                if type(at)=="number" and (type(visited[id])~="number" or at>visited[id]) then
                    visited[id]=at
                end
            end
        end
    end
    for id, at in pairs(visited) do
        if type(at) ~= "number" or os.time()-at > 3600 then visited[id] = nil end
    end
    visited[game.JobId] = os.time()
    local function saveVisited() save("Visited", Http:JSONEncode(visited)) end
    saveVisited()
    local function setAuto(value)
        auto = value
        version = version + 1
        save("Auto", value)
        autoButton.Text = value and "Auto hop: ON" or "Auto hop: OFF"
        autoButton.BackgroundColor3=value and theme.accent or theme.surface
    end
    local originalClose = closeAction
    closeAction = function()
        setAuto(false)
        save("Running", false)
        originalClose()
    end
    -- Opt-in adapter for locally exposed character flags. No immunity is assumed.
    local antiStun=false
    local stunResets=0
    local function setAntiStun(value)
        antiStun=value
        antiStunButton.Text=value and "Anti stun: ON" or "Anti stun: OFF"
        antiStunButton.BackgroundColor3=value and theme.accent or theme.surface
        antiStunStatus.Text=value and "Checking this character for compatible stun flags..."
            or "Off. Local stun recovery stopped."
    end
    table.insert(connections,antiStunButton.Activated:Connect(function()
        if not stopped then setAntiStun(not antiStun) end
    end))
    local function neutralValue(value)
        if type(value)=="boolean" then return false end
        if type(value)=="number" and value==value and math.abs(value)<1e12 and value>=0 then return 0 end
    end
    local function recoverLocalStun()
        local character=player.Character
        local humanoid=character and character:FindFirstChildOfClass("Humanoid")
        if not character or not humanoid or humanoid.Health<=0 then
            antiStunStatus.Text="Waiting for a living character..."; return
        end
        local compatible,changed=0,0
        for _,name in ipairs({"Stun","Stunned"}) do
            local flag=character:FindFirstChild(name)
            if flag and (flag:IsA("NumberValue") or flag:IsA("IntValue") or flag:IsA("BoolValue")) then
                local neutral=neutralValue(flag.Value)
                if neutral~=nil then
                    compatible=compatible+1
                    if flag.Value~=neutral then flag.Value=neutral; changed=changed+1 end
                end
            end
            local value=character:GetAttribute(name)
            local neutral=neutralValue(value)
            if neutral~=nil then
                compatible=compatible+1
                if value~=neutral then character:SetAttribute(name,neutral); changed=changed+1 end
            end
        end
        if changed>0 then
            stunResets=stunResets+changed
            -- Only release this state alongside an actual stun flag, never force a seat exit.
            if humanoid.PlatformStand and not humanoid.Sit and not humanoid.SeatPart then
                humanoid.PlatformStand=false
            end
        end
        antiStunStatus.Text=compatible>0
            and "Watching "..compatible.." local flags. Resets: "..stunResets..". Server stuns may remain."
            or "No compatible local stun flags detected. Anti stun is unavailable for this character."
    end
    task.spawn(function()
        while not stopped do
            if antiStun then
                local ok,err=pcall(recoverLocalStun)
                if not ok then
                    setAntiStun(false)
                    antiStunStatus.Text="Recovery paused: "..tostring(err):sub(1,110)
                end
            end
            task.wait(antiStun and 0.2 or 1)
        end
    end)
    local scanError = nil
    local function clean(value)
        if type(value)~="string" or #value>120 then return nil end
        value=value:gsub("[%c]",""):match("^%s*(.-)%s*$")
        if value=="" then return nil end
        return value
    end
    local function repeatedBase(value)
        if not value or #value%2~=1 then return nil end
        local mid=(#value+1)/2
        if value:sub(mid,mid)=="-" and value:sub(1,mid-1)==value:sub(mid+1) then
            return value:sub(1,mid-1)
        end
    end
    local function displayName(value)
        value=clean(value)
        if not value then return nil end
        value=repeatedBase(value) or value
        -- Preserve variant information; only strip the literal physical-tool suffix.
        value=value:gsub(" [Ff]ruit$","")
        local generic={fruit=true,tool=true,model=true,handle=true,spawned=true}
        if generic[value:lower()] or value=="" then return nil end
        return value.." Fruit"
    end
    local function identity(obj)
        local nodes={obj}
        for _,child in ipairs(obj:GetDescendants()) do
            if #nodes>=65 then break end
            table.insert(nodes,child)
        end
        -- Prefer canonical metadata over a generic outer Tool/Model named Fruit.
        for _,node in ipairs(nodes) do
            local id=clean(node:GetAttribute("OriginalName"))
            if not id and node.Name=="OriginalName" and node:IsA("StringValue") then id=clean(node.Value) end
            if id and displayName(id) then return displayName(id),id end
        end
        for _,node in ipairs(nodes) do
            for _,field in ipairs({"FruitName","DisplayName"}) do
                local value=node:GetAttribute(field)
                if node.Name==field and node:IsA("StringValue") then value=node.Value end
                local name=displayName(value)
                if name then return name,nil end
            end
        end
        for _,node in ipairs(nodes) do
            local raw=clean(node.Name)
            if raw and (raw:match(" [Ff]ruit$") or repeatedBase(raw)) then
                local name=displayName(raw)
                if name then
                    local base=raw:gsub(" [Ff]ruit$","")
                    return name,repeatedBase(raw) and raw or (base.."-"..base)
                end
            end
        end
        return "Unidentified fruit",nil
    end
    local function fruitLike(obj)
        return obj.Name:lower():find("fruit",1,true)~=nil
            or repeatedBase(clean(obj.Name))~=nil
            or repeatedBase(clean(obj:GetAttribute("OriginalName")))~=nil
    end
    local function candidate(obj)
        if not (obj:IsA("Tool") or obj:IsA("Model")) then return nil end
        if not fruitLike(obj) then return nil end
        local ancestor = obj
        while ancestor and ancestor ~= workspace do
            if ancestor:FindFirstChildOfClass("Humanoid") then return nil end
            if ancestor ~= obj and ancestor:IsA("Tool") then return nil end
            ancestor = ancestor.Parent
        end
        if ancestor ~= workspace then return nil end
        local handle = obj:FindFirstChild("Handle")
        if not handle and obj:IsA("Model") then handle = obj.PrimaryPart end
        if handle and handle:IsA("BasePart") then return handle end
    end
    local function ownsTool(tool)
        local backpack=player:FindFirstChild("Backpack")
        return tool:IsA("Tool") and tool.Parent~=nil
            and (tool.Parent==backpack or tool.Parent==player.Character)
    end
    local function heldFruits()
        local list={}
        local containers={}
        local backpack=player:FindFirstChild("Backpack")
        if backpack then table.insert(containers,backpack) end
        if player.Character then table.insert(containers,player.Character) end
        for _,container in ipairs(containers) do
            for _,tool in ipairs(container:GetChildren()) do
                -- Physical fruit tools have a Handle. Ability tools are excluded.
                local handle=tool:FindFirstChild("Handle")
                if tool:IsA("Tool") and fruitLike(tool) and handle and handle:IsA("BasePart") then
                    table.insert(list,tool)
                end
            end
        end
        return list
    end
    local found, chests, selectedFruit = {}, {}, nil
    local Collections=game:GetService("CollectionService")
    local function chestName(obj)
        local name=obj.Name:lower():gsub("[%s_%-]","")
        return name:match("^chest%d*$")~=nil or name=="goldchest"
            or name=="silverchest" or name=="diamondchest"
    end
    local function chestPosition(obj)
        if not (obj:IsA("BasePart") or obj:IsA("Model")) then return nil end
        local ancestor=obj
        while ancestor and ancestor~=workspace do
            if ancestor:GetAttribute("IsDisabled") or ancestor:GetAttribute("Collected")
                or ancestor:FindFirstChildOfClass("Humanoid") or ancestor:IsA("Tool") then return nil end
            ancestor=ancestor.Parent
        end
        if ancestor~=workspace then return nil end
        if obj:IsA("BasePart") then return obj.Position end
        if not obj:FindFirstChildWhichIsA("BasePart",true) then return nil end
        return obj:GetPivot().Position
    end
    local function scanChests(descendants,root)
        local tagged={}
        if Collections then
            local ok,result=pcall(function() return Collections:GetTagged("_ChestTagged") end)
            if ok then for _,obj in ipairs(result) do tagged[obj]=true end end
        end
        local seen, fresh={},{}
        for _,obj in ipairs(descendants) do
            if tagged[obj] or chestName(obj) then
                -- Collapse a named/tagged chest model and its parts to one target.
                local target=obj
                local ancestor=obj.Parent
                while ancestor and ancestor~=workspace do
                    if ancestor:IsA("Model") and (tagged[ancestor] or chestName(ancestor)) then target=ancestor end
                    ancestor=ancestor.Parent
                end
                if not seen[target] then
                    seen[target]=true
                    local position=chestPosition(target)
                    if position then table.insert(fresh,{object=target,
                        distance=root and (root.Position-position).Magnitude or math.huge}) end
                end
            end
        end
        table.sort(fresh,function(a,b) return a.distance<b.distance end)
        chests=fresh
    end
    local function highlightSelection()
        local chosen=selectedFruit or (found[1] and found[1].object)
        for obj,row in pairs(fruitRows) do
            local selected=obj==chosen
            row.button.Text=(selected and "> " or "  ")..row.caption
            row.button.BackgroundColor3=selected and theme.accent or theme.surface
        end
    end
    local function scan()
        local fresh, handles, alive = {}, {}, {}
        local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        local descendants=workspace:GetDescendants()
        scanChests(descendants,root)
        for _, obj in ipairs(descendants) do
            local handle = candidate(obj)
            if handle and not handles[handle] then
                handles[handle] = true
                table.insert(fresh, {object=obj, handle=handle,
                    distance=root and (root.Position-handle.Position).Magnitude or math.huge})
            end
        end
        table.sort(fresh, function(a,b) return a.distance < b.distance end)
        for i, fruit in ipairs(fresh) do
            local obj, handle = fruit.object, fruit.handle
            alive[obj] = true
            if not markers[obj] then
                local billboard = create("BillboardGui", {Adornee=handle, AlwaysOnTop=true,
                    Size=UDim2.fromOffset(210,48), StudsOffset=Vector3.new(0,3,0)}, gui)
                local label = create("TextLabel", {Size=UDim2.fromScale(1,1), BackgroundTransparency=1,
                    TextColor3=Color3.fromRGB(255,220,90), TextStrokeTransparency=0.15,
                    Font=Enum.Font.GothamBold, TextSize=14}, billboard)
                markers[obj] = {gui=billboard,label=label}
            end
            local name = identity(obj)
            local distance = fruit.distance < math.huge and tostring(math.floor(fruit.distance)).." studs" or "select a team"
            markers[obj].gui.Adornee = handle
            markers[obj].label.Text = name .. "\n" .. distance
            if not fruitRows[obj] then
                local rowButton=create("TextButton", {Name="FruitRow", Size=UDim2.new(1,-8,0,28),
                    BorderSizePixel=0, TextColor3=Color3.fromRGB(233,239,249),
                    TextSize=12, Font=Enum.Font.Gotham, TextXAlignment=Enum.TextXAlignment.Left,
                    TextTruncate=Enum.TextTruncate.AtEnd}, list)
                local connection=rowButton.Activated:Connect(function()
                    if stopped then return end
                    if not candidate(obj) then message="That fruit is no longer available."; return end
                    selectedFruit=obj
                    highlightSelection()
                    message="Selected "..identity(obj)..". Tap Teleport to fruit."
                    status.Text=message
                end)
                fruitRows[obj]={button=rowButton,connection=connection}
            end
            local row=fruitRows[obj]
            row.caption=name.." | "..distance
            row.button.Position=UDim2.fromOffset(0,(i-1)*30)
        end
        for obj, marker in pairs(markers) do
            if not alive[obj] then marker.gui:Destroy(); markers[obj]=nil end
        end
        for obj,row in pairs(fruitRows) do
            if not alive[obj] then row.connection:Disconnect(); row.button:Destroy(); fruitRows[obj]=nil end
        end
        if selectedFruit and not alive[selectedFruit] then
            selectedFruit=nil
            message="Selected fruit disappeared. The nearest available fruit is highlighted."
        end
        found = fresh
        highlightSelection()
        scans = scans+1
        emptyList.Visible=#fresh==0
        list.CanvasSize=UDim2.fromOffset(0,#fresh*30)
        details.Text = "Scan #"..scans.." | HTTP "..(canRequest and "YES" or "NO")
            .." | Restart "..(canResume and "YES" or "NO").."\nFruits: "..#fresh.." | Chests: "..#chests
        if #fresh>0 and auto then
            setAuto(false)
            message = "Fruit found! Hopping stopped. Check the yellow markers."
        end
    end
    local function safelyScan()
        local ok, err = pcall(scan)
        scanError = not ok and tostring(err) or nil
        if not ok then setAuto(false); showError(err); message="Scanner error; auto hopping disabled." end
        return ok
    end
    local moving=false
    local function moveToObject(obj,positionFn,control,buttonText,label,pickupText)
        if moving or stopped then return end
        if busy then message="Cancel the server hop before moving."; return end
        local character=player.Character
        local root=character and character:FindFirstChild("HumanoidRootPart")
        local humanoid=character and character:FindFirstChildOfClass("Humanoid")
        if not root or not humanoid or humanoid.Health<=0 then
            message="Choose a team and wait for your character."; return
        end
        if not positionFn(obj) then message="That target is no longer available."; return end
        setAuto(false)
        moving=true
        control.Text="Moving..."
        task.spawn(function()
            local ok,err=pcall(function()
                if stopped or player.Character~=character then return end
                local position=positionFn(obj)
                if not position then message="That target is no longer available."; return end
                -- Leave the target in place for the game's normal collection system.
                character:PivotTo(CFrame.new(position+Vector3.new(0,3,0)))
                message="Moved near "..label..". "..pickupText
                task.wait(1)
                if stopped or player.Character~=character then return end
                if (root.Position-position).Magnitude>30 then
                    message="The game moved you back. Teleport was not accepted."
                end
            end)
            moving=false
            if stopped then return end
            control.Text=buttonText
            if not ok then message="Teleport failed: "..tostring(err):sub(1,130) end
        end)
    end
    table.insert(connections,fruitButton.Activated:Connect(function()
        if moving or stopped then return end
        if busy then message="Cancel the server hop before teleporting to a fruit."; return end
        local requested=selectedFruit
        if not safelyScan() then return end
        if requested and selectedFruit~=requested then message="Selected fruit is no longer available. Select another."; return end
        local target=selectedFruit or (found[1] and found[1].object)
        if not target then message="No loaded fruit to teleport to."; return end
        moveToObject(target,function(obj)
            local handle=candidate(obj)
            return handle and handle.Position
        end,fruitButton,"Teleport to fruit",identity(target),"Touch it to pick it up.")
    end))
    local Tweens=game:GetService("TweenService")
    local collecting, chestRun, activeTween, travelSpeed=false,0,nil,120
    local chestAfter=setmetatable({}, {__mode="k"})
    local function cancelChest()
        collecting=false
        chestRun=chestRun+1
        if activeTween then pcall(function() activeTween:Cancel() end); activeTween=nil end
        collectButton.Text="Auto chest: OFF"
        collectButton.BackgroundColor3=theme.surface
    end
    local previousClose=closeAction
    closeAction=function() cancelChest(); previousClose() end
    table.insert(connections,stopMoveButton.Activated:Connect(function()
        cancelChest()
        message="Chest travel stopped."
        status.Text=message
    end))
    table.insert(connections,speedButton.Activated:Connect(function()
        travelSpeed=travelSpeed==120 and 180 or (travelSpeed==180 and 80 or 120)
        speedButton.Text="Speed: "..travelSpeed
    end))
    local function chestTravel(obj,epoch)
        local character=player.Character
        local root=character and character:FindFirstChild("HumanoidRootPart")
        local humanoid=character and character:FindFirstChildOfClass("Humanoid")
        if not root or not humanoid or humanoid.Health<=0 then return false,"Character unavailable; collection paused.",true end
        local function active()
            return not stopped and chestRun==epoch and player.Character==character
                and root.Parent==character and humanoid.Health>0
        end
        local params=RaycastParams.new()
        params.FilterType=Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances={character,obj}
        params.IgnoreWater=false
        params.RespectCanCollide=true
        local function clear(a,b)
            return (b-a).Magnitude<0.1 or workspace:Raycast(a,b-a,params)==nil
        end
        local function leg(goal)
            if not active() then return false,"Travel cancelled.",true end
            if not chestPosition(obj) then return false,"Target disappeared; rescanning." end
            if not clear(root.Position,goal) then return false,"Path blocked; skipping this chest." end
            local duration=math.max(0.15,(root.Position-goal).Magnitude/travelSpeed)
            local tween=Tweens:Create(root,TweenInfo.new(duration,Enum.EasingStyle.Linear),{CFrame=CFrame.new(goal)})
            activeTween=tween
            tween:Play()
            local deadline=os.clock()+duration+3
            while tween.PlaybackState==Enum.PlaybackState.Playing and os.clock()<deadline do
                if not active() then tween:Cancel(); return false,"Travel cancelled.",true end
                if not chestPosition(obj) then tween:Cancel(); return false,"Target disappeared; rescanning." end
                -- Streaming can reveal a wall during a long journey.
                if not clear(root.Position,goal) then tween:Cancel(); return false,"New obstacle detected; skipping chest." end
                task.wait(0.1)
            end
            if tween.PlaybackState~=Enum.PlaybackState.Completed then tween:Cancel(); return false,"Travel interrupted or timed out." end
            activeTween=nil
            if not active() then return false,"Travel cancelled.",true end
            task.wait(0.2)
            if not active() then return false,"Travel cancelled.",true end
            if (root.Position-goal).Magnitude>12 then return false,"Movement corrected by game; collection paused.",true end
            return true
        end
        local position=chestPosition(obj)
        if not position then return false,"Chest is no longer loaded." end
        local destination=position+Vector3.new(0,3,0)
        local origin=root.Position
        local route={destination}
        if (destination-origin).Magnitude>200 or not clear(origin,destination) then
            route=nil
            for _,height in ipairs({60,120,220}) do
                local y=math.max(origin.Y,destination.Y)+height
                local up=Vector3.new(origin.X,y,origin.Z)
                local across=Vector3.new(destination.X,y,destination.Z)
                if clear(origin,up) and clear(up,across) and clear(across,destination) then
                    route={up,across,destination}; break
                end
            end
            if not route then return false,"No clear loaded route; skipping enclosed chest." end
        end
        for _,goal in ipairs(route) do
            message="Travelling to chest ("..math.floor((root.Position-destination).Magnitude).." studs)."
            local ok,why,fatal=leg(goal)
            if not ok then return false,why,fatal end
        end
        -- Let normal character contact collect it. Never claim a reward from proximity alone.
        for attempt=1,2 do
            local deadline=os.clock()+2
            while os.clock()<deadline do
                if not active() then return false,"Travel cancelled.",true end
                if (root.Position-destination).Magnitude>18 then return false,"Movement corrected by game; collection paused.",true end
                if not chestPosition(obj) then return true,"Chest cleared nearby; check Beli for the reward." end
                task.wait(0.15)
            end
            if attempt==1 then
                local ok,why,fatal=leg(position+Vector3.new(2,2,0))
                if not ok then return false,why,fatal end
                ok,why,fatal=leg(destination)
                if not ok then return false,why,fatal end
            end
        end
        return false,"Pickup unconfirmed; skipping this chest for 60 seconds."
    end
    local function runChests(continuous)
        if moving or stopped then return end
        if busy then message="Cancel the server hop before chest travel."; return end
        if not Tweens then message="TweenService is unavailable."; return end
        setAuto(false)
        moving=true
        collecting=continuous
        chestRun=chestRun+1
        local epoch=chestRun
        collectButton.Text=collecting and "Auto chest: ON" or "Auto chest: OFF"
        collectButton.BackgroundColor3=collecting and theme.accent or theme.surface
        chestButton.Text="Travelling..."
        task.spawn(function()
            local ok,err=pcall(function()
                repeat
                    if stopped or epoch~=chestRun then break end
                    if not safelyScan() then break end
                    local target
                    for _,chest in ipairs(chests) do
                        if os.clock()>=(chestAfter[chest.object] or 0) then target=chest.object; break end
                    end
                    if not target then
                        message="No ready loaded chest. Explore to load more islands."
                        if not continuous then break end
                        task.wait(2)
                    else
                        local cleared,why,fatal=chestTravel(target,epoch)
                        if epoch~=chestRun or stopped then break end
                        message=why
                        chestAfter[target]=os.clock()+(cleared and 10 or 60)
                        if fatal then break end
                        task.wait(0.5)
                    end
                until not continuous
            end)
            if activeTween then pcall(function() activeTween:Cancel() end); activeTween=nil end
            collecting=false
            moving=false
            if stopped then return end
            collectButton.Text="Auto chest: OFF"
        collectButton.BackgroundColor3=theme.surface
            chestButton.Text="Tween to chest"
            if not ok then message="Chest travel stopped: "..tostring(err):sub(1,130) end
            status.Text=message
        end)
    end
    table.insert(connections,chestButton.Activated:Connect(function() runChests(false) end))
    table.insert(connections,collectButton.Activated:Connect(function()
        if collecting then cancelChest(); message="Auto chest stopped." else runChests(true) end
    end))
    -- Factory timers are estimates anchored to an observed event in THIS server.
    -- Joining time and workspace.DistributedGameTime are not raid schedules.
    local secondSea=game.PlaceId==4442272183
    local factoryServers={}
    local kinds={manual=true,core=true,success=true,failure=true,warning=true,active=true,legacy=true}
    local function finite(value)
        return type(value)=="number" and value==value and math.abs(value)<1e12
    end
    local function mergeFactory(job,record)
        if type(job)~="string" or job=="" or #job>128 or type(record)~="table" then return end
        local at=record.observedAt
        if not finite(at) or at>os.time()+5 or os.time()-at>21600 then return end
        local fresh={job=job,observedAt=at,kind=kinds[record.kind] and record.kind or "legacy"}
        for field,duration in pairs({nextAt=5400,openingAt=30,activeUntil=300}) do
            local value=record[field]
            if finite(value) and math.abs(value-at-duration)<2 then fresh[field]=value end
        end
        if not fresh.nextAt and not fresh.openingAt and not fresh.activeUntil then return end
        local previous=factoryServers[job]
        if not previous or fresh.observedAt>previous.observedAt then factoryServers[job]=fresh end
    end
    local rawServers=read("FactoryServersV8")
    if type(rawServers)=="string" then
        local ok,records=pcall(function() return Http:JSONDecode(rawServers) end)
        if ok and type(records)=="table" then for job,record in pairs(records) do mergeFactory(job,record) end end
    end
    if type(env.FruitScoutFactoryServers)=="table" then
        for job,record in pairs(env.FruitScoutFactoryServers) do mergeFactory(job,record) end
    end
    -- Migrate a valid v7 observation without replacing a newer multi-server entry.
    local function migrateFactory(record)
        if type(record)~="table" then return end
        if finite(record.nextAt) then
            mergeFactory(record.job,{nextAt=record.nextAt,observedAt=record.nextAt-5400,kind="legacy"})
        elseif finite(record.openingAt) then
            mergeFactory(record.job,{openingAt=record.openingAt,observedAt=record.openingAt-30,kind="warning"})
        end
    end
    migrateFactory(env.FruitScoutFactory)
    local legacy=read("Factory")
    if type(legacy)=="string" then
        local ok,record=pcall(function() return Http:JSONDecode(legacy) end)
        if ok then migrateFactory(record) end
    end
    local factory=factoryServers[game.JobId] or {job=game.JobId}
    local function saveFactory()
        if factory.observedAt then factoryServers[game.JobId]=factory end
        local entries={}
        for job,record in pairs(factoryServers) do
            if os.time()-record.observedAt>21600 then factoryServers[job]=nil
            else table.insert(entries,{job=job,at=record.observedAt}) end
        end
        table.sort(entries,function(a,b) return a.at>b.at end)
        for i=65,#entries do factoryServers[entries[i].job]=nil end
        env.FruitScoutFactoryServers=factoryServers
        save("FactoryServersV8",Http:JSONEncode(factoryServers))
    end
    saveFactory()
    local function factoryEnded(kind)
        -- A death signal and its announcement describe one raid, not two resets.
        if kind~="manual" and factory.nextAt and factory.observedAt
            and os.time()-factory.observedAt<10 then return end
        factory.observedAt=os.time()
        factory.kind=kind
        factory.nextAt=os.time()+5400
        factory.openingAt=nil
        factory.activeUntil=nil
        saveFactory()
    end
    table.insert(connections,syncFactoryButton.Activated:Connect(function()
        if not secondSea then return end
        factoryEnded("manual")
        message="Factory estimate synced to your report that the raid just ended."
    end))
    local notificationSeen=setmetatable({}, {__mode="k"})
    local notificationReady=false
    local trackedCore, coreDeath=nil,nil
    local closeWithTravel=closeAction
    closeAction=function()
        if coreDeath then coreDeath:Disconnect() end
        closeWithTravel()
    end
    local function minutesSeconds(seconds)
        seconds=math.max(0,math.ceil(seconds))
        return string.format("%02d:%02d",math.floor(seconds/60),seconds%60)
    end
    local function updateFactory()
        if not secondSea then factoryStatus.Text="Factory: Second Sea only."; return end
        -- Ignore chat and Scout's own labels. Only a changing game notification counts.
        local event,priority=nil,0
        for _,obj in ipairs(parent:GetDescendants()) do
            if obj:IsA("TextLabel") and not obj:IsDescendantOf(gui) then
                local ancestor=obj.Parent
                local notification,chat,visible=false,false,obj.Visible
                while ancestor and ancestor~=parent do
                    local name=ancestor.Name:lower()
                    if name:find("notification",1,true) then notification=true end
                    if name:find("chat",1,true) then chat=true end
                    if ancestor:IsA("GuiObject") and not ancestor.Visible then visible=false end
                    if ancestor:IsA("ScreenGui") and not ancestor.Enabled then visible=false end
                    ancestor=ancestor.Parent
                end
                local value=obj.Text
                if notificationReady and notification and not chat and visible and notificationSeen[obj]~=value then
                    local plain=value:gsub("<[^>]*>",""):lower():gsub("%s+"," ")
                    local matched,rank
                    if plain:find("101 factory malffffunction. end.",1,true) then matched,rank="success",3
                    elseif plain:find("factory poison control activated. all staff return to work immediately",1,true) then matched,rank="failure",3
                    elseif plain:find("the factory has been breached. poison control activating in 5 minutes",1,true) then matched,rank="active",2
                    elseif plain:find("we are breaching the factory in 30 seconds",1,true) then matched,rank="warning",1 end
                    if matched and rank>priority then event,priority=matched,rank end
                end
                notificationSeen[obj]=value
            end
        end
        notificationReady=true
        if event=="success" or event=="failure" then factoryEnded(event)
        elseif event then
            if factory.kind~=event or not factory.observedAt or os.time()-factory.observedAt>5 then
                factory={job=game.JobId,observedAt=os.time(),kind=event}
                if event=="warning" then factory.openingAt=os.time()+30
                else factory.activeUntil=os.time()+300 end
                saveFactory()
            end
        end
        local enemies=workspace:FindFirstChild("Enemies")
        local core=enemies and enemies:FindFirstChild("Core")
        local humanoid=core and core:FindFirstChildOfClass("Humanoid")
        if core~=trackedCore then
            if coreDeath then coreDeath:Disconnect(); coreDeath=nil end
            trackedCore=core
            if humanoid and humanoid.Health>0 then
                coreDeath=humanoid.Died:Connect(function()
                    if not stopped then factoryEnded("core") end
                end)
            end
        end
        if humanoid and humanoid.Health>0 then
            factoryStatus.Text="Factory: ACTIVE (Core detected)."
        elseif factory.activeUntil and factory.activeUntil>os.time() then
            factoryStatus.Text="Factory: ACTIVE (announcement).\nUp to ~"..minutesSeconds(factory.activeUntil-os.time()).." left."
        elseif factory.openingAt then
            local remaining=factory.openingAt-os.time()
            factoryStatus.Text=remaining>0 and "Factory opens in ~"..minutesSeconds(remaining)
                or "Factory: expected active; awaiting end sync."
            if remaining < -330 then factory.openingAt=nil; saveFactory() end
        elseif factory.nextAt then
            local remaining=factory.nextAt-os.time()
            factoryStatus.Text=remaining>0 and "Factory next raid: ~"..minutesSeconds(remaining).." (estimate)\nSaved for this server: "..factory.kind
                or "Factory estimate elapsed; awaiting a game signal."
        else
            factoryStatus.Text="Factory: time unknown in this server. Sync after a raid ends."
        end
    end
    task.spawn(function()
        while not stopped do
            local ok=pcall(updateFactory)
            if not ok then factoryStatus.Text="Factory: signal unavailable; manual sync supported." end
            task.wait(1)
        end
    end)
    local autoStore=read("AutoStore")==true
    local storeAfter=setmetatable({}, {__mode="k"})
    local function setStore(value)
        autoStore=value
        save("AutoStore",value)
        storeButton.Text=value and "Auto store: ON" or "Auto store: OFF"
        storeButton.BackgroundColor3=value and theme.accent or theme.surface
    end
    setStore(autoStore)
    if autoStore then storeStatus.Text="Auto store enabled for physical fruits in your backpack or hand." end
    table.insert(connections,storeButton.Activated:Connect(function()
        setStore(not autoStore)
        storeStatus.Text=autoStore and "Auto store enabled for physical fruits in your backpack or hand."
            or "Auto store off. A request already sent may still finish."
    end))
    local function storeOne(tool)
        local name,id=identity(tool)
        storeAfter[tool]=os.clock()+30
        if not id then storeStatus.Text="Cannot store "..name..": storage ID is unavailable."; return end
        local replicated=game:GetService("ReplicatedStorage")
        local remotes=replicated and replicated:FindFirstChild("Remotes")
        local remote=remotes and remotes:FindFirstChild("CommF_")
        if not remote or not remote:IsA("RemoteFunction") then
            setStore(false)
            storeStatus.Text="Auto store unavailable: game storage interface not found."
            return
        end
        if stopped or not autoStore or not ownsTool(tool) or env.FruitScoutStorePending then return end
        local pending={}
        env.FruitScoutStorePending=pending
        local done,ok,result=false,false,nil
        storeStatus.Text="Requesting storage for "..name.."..."
        task.spawn(function()
            ok,result=pcall(function()
                if stopped or not autoStore or not ownsTool(tool) then return "Cancelled before sending" end
                return remote:InvokeServer("StoreFruit",id,tool)
            end)
            done=true
            if env.FruitScoutStorePending==pending then env.FruitScoutStorePending=nil end
        end)
        local deadline=os.clock()+12
        while not done and not stopped and os.clock()<deadline do task.wait(0.2) end
        if stopped then return end
        if not done then
            setStore(false)
            storeStatus.Text="Storage timed out; auto store paused. The pending request may still finish."
        elseif not autoStore then
            return
        elseif not ok then
            storeStatus.Text="Storage error: "..tostring(result):sub(1,140)
        elseif type(result)=="string" and result~="" then
            storeStatus.Text="Storage: "..result:sub(1,145)
        elseif result==false then
            storeStatus.Text="Storage rejected for "..name..". Check inventory capacity."
        else
            storeStatus.Text="Storage request finished for "..name..". Check your game inventory."
        end
    end
    task.spawn(function()
        while not stopped do
            if autoStore and not env.FruitScoutStorePending and not busy then
                for _,tool in ipairs(heldFruits()) do
                    if os.clock()>=(storeAfter[tool] or 0) then
                        local ok,err=pcall(storeOne,tool)
                        if not ok then setStore(false); storeStatus.Text="Auto store error: "..tostring(err):sub(1,130) end
                        break
                    end
                end
            end
            task.wait(2)
        end
    end)
    local function httpPage(url, stillActive)
        local done, response, failure = false, nil, nil
        task.spawn(function()
            local ok, result = pcall(requestFn, {Url=url,Method="GET"})
            if ok then response=result else failure=result end
            done=true
        end)
        local untilTime = os.clock()+20
        while not done and os.clock()<untilTime and stillActive() do task.wait(0.2) end
        if not stillActive() then return nil end
        if not done then error("Server request timed out") end
        if failure then error(tostring(failure)) end
        if type(response)~="table" then error("Invalid HTTP response") end
        local code=tonumber(response.StatusCode or response.Status)
        if code~=200 then error("Server list HTTP "..tostring(code).."; retry after 60 seconds") end
        local data=Http:JSONDecode(response.Body)
        if type(data)~="table" or type(data.data)~="table" then error("Unexpected server list format") end
        return data
    end
    local failedTeleport, targetServer=false,nil
    table.insert(connections,TP.TeleportInitFailed:Connect(function(who,_,err,placeId,options)
        if who~=player or not busy or not targetServer then return end
        if placeId and placeId~=game.PlaceId then return end
        local failedId=options and options.ServerInstanceId
        if failedId and failedId~="" and failedId~=targetServer then return end
        failedTeleport=true
        message="Join failed: "..tostring(err):sub(1,100)
    end))
    local function hop()
        if busy or stopped then return end
        if moving or env.FruitScoutStorePending or #heldFruits()>0 then
            message="Store your held fruits before hopping."; return
        end
        if os.clock()<retryAfter then message="Waiting before retrying the server request."; return end
        if not canRequest then message="Delta HTTP request support is unavailable."; return end
        if not safelyScan() or #found>0 then message="Hop stopped: fruit found or scanner error."; return end
        if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
            message="Choose a team and wait for your character before hopping."; return
        end
        busy=true
        hopButton.Text="Cancel hop"
        retryAfter=os.clock()+10
        local epoch=version
        local function active() return not stopped and version==epoch end
        local ok, err=pcall(function()
            local cursor, page, attempts=nil,0,0
            local pool, seen, cursors={}, {}, {}
            local exhausted=false
            local function nextServer()
                while #pool==0 and not exhausted and page<5 and active() do
                page=page+1
                message="Checking public servers, page "..page
                local url="https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100&excludeFullGames=true"
                if cursor then url=url.."&cursor="..Http:UrlEncode(cursor) end
                local data=httpPage(url,active)
                if not data or not active() then return end
                for _, server in ipairs(data.data) do
                    if type(server.id)=="string" and server.id~="" and server.id~=game.JobId
                        and not visited[server.id] and not seen[server.id]
                        and type(server.playing)=="number" and type(server.maxPlayers)=="number"
                        and server.playing<server.maxPlayers then
                        seen[server.id]=true
                        table.insert(pool,server.id)
                    end
                end
                -- Shuffle each page so every search doesn't start at the same listed server.
                for i=#pool,2,-1 do
                    local j=math.random(i)
                    pool[i],pool[j]=pool[j],pool[i]
                end
                cursor=data.nextPageCursor
                exhausted=type(cursor)~="string" or cursor=="" or cursors[cursor]==true
                if not exhausted then cursors[cursor]=true end
                if #pool==0 and not exhausted and page<5 then task.wait(2) end
                end
                return table.remove(pool)
            end
            while active() and attempts<8 do
            local chosen=nextServer()
            if not active() then return end
            if not chosen then error("No more unvisited open servers in the pages checked. Try again later.") end
            if moving or env.FruitScoutStorePending or #heldFruits()>0 then
                message="Hop stopped: you have an un-stored fruit."; return
            end
            if not safelyScan() or #found>0 or not active() then message="Hop stopped by new scan."; return end
            if canResume and not queued then
                local queuedCode=string.format(
                    "if not game:IsLoaded() then game.Loaded:Wait() end\nlocal t=game:GetService('TeleportService')\n"
                    .."local ok,on=pcall(function() return t:GetTeleportSetting(%q) end)\n"
                    .."if ok and on then local s=%q; local f=assert(loadstring(s)); f(s,true) end",
                    key.."Running",SOURCE)
                local queueResult=queueFn(queuedCode)
                if queueResult==false then error("Delta rejected the restart queue") end
                queued=true
            end
            visited[chosen]=os.time(); saveVisited()
            attempts=attempts+1
            failedTeleport=false
            targetServer=chosen
            message="Joining server "..attempts.."/8 ("..chosen:sub(1,8)..")..."
                ..(not canResume and " Rerun script after arrival." or "")
            -- Deprecated client API; failure is reported visibly.
            local joined,joinError=pcall(function() TP:TeleportToPlaceInstance(game.PlaceId,chosen,player) end)
            if not joined then failedTeleport=true; message="Join failed: "..tostring(joinError):sub(1,100) end
            local timeout=os.clock()+25
            while active() and not failedTeleport and os.clock()<timeout do task.wait(0.25) end
            targetServer=nil
            if not active() then return end
            local reason=failedTeleport and message or "Join timed out"
            if attempts>=8 then error("8 different servers failed. Last result: "..reason) end
            -- Pace retries and recheck cancellation/fruit detection before selecting again.
            for remaining=5,1,-1 do
                if not active() then return end
                if not safelyScan() or #found>0 then message="Fruit found or scanner error; hopping stopped."; return end
                message=reason..". Trying a different server in "..remaining.."s."
                task.wait(1)
            end
            end
        end)
        targetServer=nil
        busy=false
        hopButton.Text="Hop once"
        if active() then
            nextHop=os.clock()+60
            retryAfter=nextHop
            if not ok then message=tostring(err):sub(1,165); warn(message) end
        end
    end
    table.insert(connections,autoButton.Activated:Connect(function()
        if moving then message="Stop chest travel before enabling server hopping."
        elseif auto then setAuto(false); message="Auto hopping paused. Scanner stays active."
        elseif not canRequest or not canResume then message="Auto hop unavailable. Check HTTP/Restart above. Hop once needs HTTP."
        else setAuto(true); nextHop=os.clock()+40; message="Auto search started" end
    end))
    table.insert(connections,hopButton.Activated:Connect(function()
        if busy then
            setAuto(false)
            message="Hop retries cancelled. A join already sent may still finish."
            return
        end
        task.spawn(hop)
    end))
    table.insert(connections,scanButton.Activated:Connect(function()
        safelyScan()
        if not scanError then message=#found>0 and "Fruit candidates found. Check yellow markers." or "Scan complete. No loaded fruit found." end
    end))
    if resumeAuto and canRequest and canResume then setAuto(true) end
    task.spawn(function()
        while not stopped do
            fitPhone()
            safelyScan()
            if auto and not busy then
                if moving or env.FruitScoutStorePending or #heldFruits()>0 then
                    nextHop=os.clock()+40
                    message="Hopping paused: store your held fruits first."
                elseif not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
                    nextHop=os.clock()+40
                    message="Select a team to continue the search."
                    if type(firesignal)=="function" and os.clock()-lastTeamAttempt>=3 then
                        lastTeamAttempt=os.clock()
                        pcall(function()
                            local main=parent:FindFirstChild("Main (minimal)")
                            local choose=main and main:FindFirstChild("ChooseTeam")
                            local container=choose and choose:FindFirstChild("Container")
                            local team=container and container:FindFirstChild("Pirates")
                            local frame=team and team:FindFirstChild("Frame")
                            local join=frame and frame:FindFirstChild("TextButton")
                            if join then firesignal(join.Activated) end
                        end)
                    end
                elseif os.clock()>=nextHop then task.spawn(hop) end
            end
            if not scanError then
                status.Text=message..(auto and not busy and "\nNext hop in "..math.max(0,math.ceil(nextHop-os.clock())).."s" or "")
            end
            task.wait(2)
        end
    end)
    status.Text="Scanner is running. Tap Auto hop to search more servers."
end
local ok, err=xpcall(setup,function(problem) return tostring(problem) end)
if not ok then showError(err) end
]====]
if type(loadstring) ~= "function" then
    message.Text = "KARMA stopped: loadstring is unavailable in this execution environment."
else
    local run, compileError = loadstring(SOURCE)
    if not run then
        message.Text = "Compile error: " .. tostring(compileError)
    else
        local ok, runtimeError = pcall(run, SOURCE, false)
        if not ok then
            warn("KARMA startup: " .. tostring(runtimeError))
            if boot.Parent then message.Text = "Startup error: " .. tostring(runtimeError) end
        end
    end
end
