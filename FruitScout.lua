-- FRUIT SCOUT MOBILE v5. Paste this entire file into the executor editor.
-- Hide/reopen with the floating Scout button. Drag the title or floating button.
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
message.Text = "FRUIT SCOUT: code started. Loading panel..."
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
local gui = create("ScreenGui", {Name="FruitScout", ResetOnSpawn=false, DisplayOrder=1000}, parent)
local panel = create("Frame", {Name="ScoutWindow", Active=true, Visible=true,
    Size=UDim2.fromOffset(300, 374), Position=UDim2.fromOffset(12, 54),
    BackgroundColor3=Color3.fromRGB(22, 26, 36), BorderSizePixel=0}, gui)
create("UICorner", {CornerRadius=UDim.new(0, 12)}, panel)
local scale = create("UIScale", {Scale=1}, panel)
local clampUI = function() end
local function fitPhone()
    local camera=workspace.CurrentCamera
    if camera then
        local size=camera.ViewportSize
        scale.Scale=math.max(0.4,math.min(1,(size.X-24)/300,(size.Y-80)/374))
    end
    clampUI()
end
fitPhone()
local function text(value, y, h, size)
    return create("TextLabel", {Text=value, Position=UDim2.fromOffset(12,y), Size=UDim2.new(1,-24,0,h),
        BackgroundTransparency=1, TextColor3=Color3.fromRGB(233,239,249), TextSize=size or 13,
        Font=Enum.Font.Gotham, TextWrapped=true, TextXAlignment=Enum.TextXAlignment.Left,
        TextYAlignment=Enum.TextYAlignment.Top}, panel)
end
local titleBar = text("FRUIT SCOUT v5  -  drag to move", 8, 32, 15)
titleBar.Name = "DragHandle"
titleBar.Active = true
local status = text("Script started. Preparing scanner...", 43, 46, 14)
local details = text("", 92, 26, 11)
local list = text("", 123, 79, 13)
local function button(value, x, y, width)
    return create("TextButton", {Text=value, Position=UDim2.fromOffset(x,y), Size=UDim2.fromOffset(width,34),
        BackgroundColor3=Color3.fromRGB(55,78,119), TextColor3=Color3.new(1,1,1),
        TextSize=13, Font=Enum.Font.Gotham}, panel)
end
local autoButton = button("Auto hop: OFF", 12, 207, 135)
local hopButton = button("Hop once", 153, 207, 135)
local scanButton = button("Scan now", 12, 248, 135)
local closeButton = button("Hide", 153, 248, 135)
local fruitButton = button("Teleport to fruit", 12, 289, 135)
local storeButton = button("Auto store: OFF", 153, 289, 135)
local storeStatus = text("Teleport targets the nearest loaded fruit. Auto store is off.", 331, 34, 11)
storeStatus.Name = "StorageStatus"
local launcher = create("TextButton", {Name="ScoutToggle", Text="Hide Scout", Active=true,
    Size=UDim2.fromOffset(124,36), Position=UDim2.fromOffset(12,8),
    BackgroundColor3=Color3.fromRGB(55,78,119), TextColor3=Color3.new(1,1,1),
    TextSize=14, Font=Enum.Font.GothamBold}, gui)
create("UICorner", {CornerRadius=UDim.new(0,10)}, launcher)
local stopped, busy, auto, version = false, false, false, 0
local connections, markers = {}, {}
local saveView = function() end
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
    launcher.Text=value and "Hide Scout" or "Open Scout"
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
    gui:Destroy()
end
env.FruitScoutClose = function() closeAction() end
table.insert(connections, closeButton.Activated:Connect(function() setVisible(false) end))

local function showError(err)
    auto = false
    version = version + 1
    autoButton.Text = "Auto hop: OFF"
    status.Text = "Error: " .. tostring(err):sub(1,180)
    warn("Fruit Scout: " .. tostring(err))
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
            buttonX=launcher.Position.X.Offset,buttonY=launcher.Position.Y.Offset}))
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
    end
    local originalClose = closeAction
    closeAction = function()
        setAuto(false)
        save("Running", false)
        originalClose()
    end
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
    local found = {}
    local function scan()
        local fresh, handles, alive = {}, {}, {}
        local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        for _, obj in ipairs(workspace:GetDescendants()) do
            local handle = candidate(obj)
            if handle and not handles[handle] then
                handles[handle] = true
                table.insert(fresh, {object=obj, handle=handle,
                    distance=root and (root.Position-handle.Position).Magnitude or math.huge})
            end
        end
        table.sort(fresh, function(a,b) return a.distance < b.distance end)
        local lines = {}
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
            if i <= 4 then table.insert(lines,name .. " | " .. distance) end
        end
        for obj, marker in pairs(markers) do
            if not alive[obj] then marker.gui:Destroy(); markers[obj]=nil end
        end
        found = fresh
        scans = scans+1
        list.Text = #lines>0 and table.concat(lines,"\n") or "No loaded fruit candidates found."
        details.Text = "Scan #"..scans.." | HTTP "..(canRequest and "YES" or "NO")
            .." | Restart "..(canResume and "YES" or "NO")
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
    table.insert(connections,fruitButton.Activated:Connect(function()
        if moving or stopped then return end
        if busy then message="Cancel the server hop before teleporting to a fruit."; return end
        if not safelyScan() then return end
        local selected=found[1]
        if not selected then message="No loaded fruit to teleport to."; return end
        local character=player.Character
        local root=character and character:FindFirstChild("HumanoidRootPart")
        local humanoid=character and character:FindFirstChildOfClass("Humanoid")
        if not root or not humanoid or humanoid.Health<=0 then
            message="Choose a team and wait for your character."; return
        end
        local handle=candidate(selected.object)
        if not handle or handle~=selected.handle then message="That fruit is no longer available."; return end
        setAuto(false)
        moving=true
        fruitButton.Text="Moving..."
        task.spawn(function()
            local name=identity(selected.object)
            local ok,err=pcall(function()
                if stopped or player.Character~=character or candidate(selected.object)~=handle then return end
                -- Move the character, leaving the world fruit for the normal pickup system.
                character:PivotTo(CFrame.new(handle.Position+Vector3.new(0,3,0)))
                message="Moved near "..name..". Touch it to pick it up."
                task.wait(1)
                if stopped or player.Character~=character then return end
                if (root.Position-handle.Position).Magnitude>30 then
                    message="The game moved you back. Teleport to fruit was not accepted."
                end
            end)
            moving=false
            if stopped then return end
            fruitButton.Text="Teleport to fruit"
            if not ok then message="Fruit teleport failed: "..tostring(err):sub(1,130) end
        end)
    end))
    local autoStore=read("AutoStore")==true
    local storeAfter=setmetatable({}, {__mode="k"})
    local function setStore(value)
        autoStore=value
        save("AutoStore",value)
        storeButton.Text=value and "Auto store: ON" or "Auto store: OFF"
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
        if auto then setAuto(false); message="Auto hopping paused. Scanner stays active."
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
    message.Text = "Fruit Scout stopped: loadstring is unavailable in this execution environment."
else
    local run, compileError = loadstring(SOURCE)
    if not run then
        message.Text = "Compile error: " .. tostring(compileError)
    else
        local ok, runtimeError = pcall(run, SOURCE, false)
        if not ok then
            warn("Fruit Scout startup: " .. tostring(runtimeError))
            if boot.Parent then message.Text = "Startup error: " .. tostring(runtimeError) end
        end
    end
end
