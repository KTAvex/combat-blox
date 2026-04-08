-- ================================================================================
--                    EXO HUB v7.0 - Matcha LuaVM (HOTKEY LIST FIX)
--                    dc: ktavex_
-- ================================================================================

local Players = game:GetService("Players")
local player  = Players.LocalPlayer or Players:FindFirstChildOfClass("Player")
local runService = game:GetService("RunService")

-- ================================================================================
--              SAVED CONFIG
-- ================================================================================
local cfg = {
    boostOn    = false,
    boostKey   = 0x70,
    boostKeyName = "F1",
    boostSpeed = 410,
    boostDur   = 0.3,
    boostDurMs = 3,

    flameBoostOn = false,
    flameBoostSpeed = 500,
    flameBoostDurMs = 5,
    flameBoostY = 50,

    rxKey      = 0x47,
    rxKeyName  = "G",

    f1cKey     = 0x48,
    f1cKeyName = "H",
    f1cDelay1  = 80,
    f1cDelay2  = 80,

    desyncKey  = 0x56,
    desyncKeyName = "V",
    desyncDelay1 = 50,
    desyncDelay2 = 50,

    menuKey    = 0x73,
    menuKeyName= "F4",
    
    hkListKey  = 0x74,
    hkListKeyName = "F5",
    
    customMacros = {},
}

-- ================================================================================
--              STATE
-- ================================================================================
local state = {
    menuVisible  = true,
    currentTab   = 1,
    bindingTarget= nil,
    boosting     = false,
    flameBoosting = false,
    wasZFire     = false,
    hkListShow   = true,
    
    dragging     = false,
    dragOffsetX  = 0,
    dragOffsetY  = 0,
    
    resizing     = false,
    resizeOffsetX = 0,
    resizeOffsetY = 0,
    
    menuX        = 60,
    menuY        = 80,
    menuW        = 340,
    menuH        = 420,
    minW         = 300,
    minH         = 350,
    
    lastPixelFire = 0,
    editingInputValKey = nil,
    inputBuffer = "",
}

-- ================================================================================
--              KEY UTILS
-- ================================================================================
local wasKeys = {}

local VK_NAMES = {
    [0x30]="0",[0x31]="1",[0x32]="2",[0x33]="3",[0x34]="4",
    [0x35]="5",[0x36]="6",[0x37]="7",[0x38]="8",[0x39]="9",
    [0x41]="A",[0x42]="B",[0x43]="C",[0x44]="D",[0x45]="E",
    [0x46]="F",[0x47]="G",[0x48]="H",[0x49]="I",[0x4A]="J",
    [0x4B]="K",[0x4C]="L",[0x4D]="M",[0x4E]="N",[0x4F]="O",
    [0x50]="P",[0x51]="Q",[0x52]="R",[0x53]="S",[0x54]="T",
    [0x55]="U",[0x56]="V",[0x57]="W",[0x58]="X",[0x59]="Y",
    [0x5A]="Z",
    [0x70]="F1",[0x71]="F2",[0x72]="F3",[0x73]="F4",[0x74]="F5",
    [0x75]="F6",[0x76]="F7",[0x77]="F8",[0x78]="F9",[0x79]="F10",
    [0x20]="Space",[0x10]="Shift",[0x11]="Ctrl",[0x12]="Alt",
    [0x08]="Back",[0x0D]="Enter",
}

local VK_CHARS = {
    [0x30]="0",[0x31]="1",[0x32]="2",[0x33]="3",[0x34]="4",
    [0x35]="5",[0x36]="6",[0x37]="7",[0x38]="8",[0x39]="9",
    [0x41]="a",[0x42]="b",[0x43]="c",[0x44]="d",[0x45]="e",
    [0x46]="f",[0x47]="g",[0x48]="h",[0x49]="i",[0x4A]="j",
    [0x4B]="k",[0x4C]="l",[0x4D]="m",[0x4E]="n",[0x4F]="o",
    [0x50]="p",[0x51]="q",[0x52]="r",[0x53]="s",[0x54]="t",
    [0x55]="u",[0x56]="v",[0x57]="w",[0x58]="x",[0x59]="y",
    [0x5A]="z",[0x20]=" ",
}

local function getKeyName(k) 
    if k and VK_NAMES[k] then return VK_NAMES[k] end
    return "?"
end

local function detectKeyboardKey()
    for vk, name in pairs(VK_NAMES) do
        if iskeypressed(vk) then 
            return vk, name 
        end
    end
    return nil, nil
end

-- ================================================================================
--              DRAWING HELPERS
-- ================================================================================
local function makeRect(x, y, w, h, color, filled, transp)
    local r = Drawing.new("Square")
    r.Position     = Vector2.new(x, y)
    r.Size         = Vector2.new(w, h)
    r.Color        = color
    r.Filled       = filled ~= false
    r.Transparency = transp or 1
    r.Visible      = true
    return r
end

local function makeTxt(x, y, txt, color, sz, center)
    local t = Drawing.new("Text")
    t.Position = Vector2.new(x, y)
    t.Text     = txt
    t.Color    = color
    t.Size     = sz or 13
    t.Font     = 2
    t.Outline  = true
    t.Center   = center or false
    t.Visible  = true
    return t
end

local function makeLine(x1, y1, x2, y2, color, thick)
    local l = Drawing.new("Line")
    l.From      = Vector2.new(x1, y1)
    l.To        = Vector2.new(x2, y2)
    l.Color     = color
    l.Thickness = thick or 1
    l.Visible   = true
    return l
end

-- ================================================================================
--              COLORS
-- ================================================================================
local C = {
    bg          = Color3.fromRGB(15, 15, 20),
    panel       = Color3.fromRGB(22, 22, 30),
    panelLight  = Color3.fromRGB(28, 28, 38),
    topbar      = Color3.fromRGB(18, 18, 25),
    accent      = Color3.fromRGB(138, 43, 226),
    accentHi    = Color3.fromRGB(167, 94, 255),
    accentDim   = Color3.fromRGB(75, 0, 130),
    border      = Color3.fromRGB(45, 45, 60),
    borderHi    = Color3.fromRGB(90, 90, 120),
    text        = Color3.fromRGB(235, 235, 245),
    textDim     = Color3.fromRGB(140, 140, 160),
    on          = Color3.fromRGB(46, 204, 113),
    onDim       = Color3.fromRGB(30, 130, 76),
    off         = Color3.fromRGB(231, 76, 60),
    offDim      = Color3.fromRGB(150, 50, 40),
    white       = Color3.fromRGB(255, 255, 255),
    yellow      = Color3.fromRGB(241, 196, 15),
    cyan        = Color3.fromRGB(26, 188, 156),
    tabOn       = Color3.fromRGB(138, 43, 226),
    tabOff      = Color3.fromRGB(30, 30, 40),
}

-- ================================================================================
--              DRAWING STORAGE
-- ================================================================================
local drawings = {
    frame = {},
    content = {},
    hkList = {},
    pingText = nil,
}

local hkState = {
    x        = 10,
    y        = 200,
    w        = 210,
    minW     = 160,
    minH     = 80,
}

local contentDraws = {
    toggles = {},
    keybinds = {},
    sliders = {},
    buttons = {},
    inputs = {},
}

local function clearDrawings(tbl)
    for _, d in pairs(tbl) do
        d.Visible = false
        pcall(function() d:Remove() end)
    end
end

-- ================================================================================
--              MENU BUILDING
-- ================================================================================
local function rebuildMenu()
    clearDrawings(drawings.frame)
    drawings.frame = {}
    
    local MX, MY = state.menuX, state.menuY
    local MW, MH = state.menuW, state.menuH
    local TAB_H  = 32
    local TABS   = {"Boost", "Blatant", "Settings"}
    
    table.insert(drawings.frame, makeRect(MX+3, MY+3, MW, MH, Color3.fromRGB(0, 0, 0), true, 0.7))
    table.insert(drawings.frame, makeRect(MX-1, MY-1, MW+2, MH+2, C.borderHi, true))
    table.insert(drawings.frame, makeRect(MX, MY, MW, MH, C.bg, true, 0.95))
    
    table.insert(drawings.frame, makeRect(MX, MY, MW, 38, C.topbar, true))
    table.insert(drawings.frame, makeRect(MX, MY, MW, 3, C.accent, true))
    
    local title = makeTxt(MX+MW/2, MY+10, "EXO HUB", C.white, 18, true)
    table.insert(drawings.frame, title)
    local subtitle = makeTxt(MX+MW/2, MY+26, "dc: ktavex_", C.textDim, 10, true)
    table.insert(drawings.frame, subtitle)
    
    table.insert(drawings.frame, makeRect(MX+MW-18, MY+MH-6,  14, 2, C.accentHi, true))
    table.insert(drawings.frame, makeRect(MX+MW-12, MY+MH-11, 8,  2, C.accentHi, true))
    table.insert(drawings.frame, makeRect(MX+MW-6,  MY+MH-16, 2,  12, C.accentHi, true))
    
    local TAB_W = MW / #TABS
    for i, name in ipairs(TABS) do
        local tx = MX + (i-1) * TAB_W
        local ty = MY + 38
        local isActive = (i == state.currentTab)
        
        if isActive then
            table.insert(drawings.frame, makeRect(tx, ty, TAB_W, TAB_H, C.tabOn, true))
            table.insert(drawings.frame, makeRect(tx, ty, TAB_W, 2, C.white, true))
        else
            table.insert(drawings.frame, makeRect(tx, ty, TAB_W, TAB_H, C.tabOff, true))
        end
        
        local txtColor = isActive and C.white or C.textDim
        local tabTxt = makeTxt(tx + TAB_W/2, ty + 10, name, txtColor, 13, true)
        table.insert(drawings.frame, tabTxt)
    end
    
    table.insert(drawings.frame, makeLine(MX, MY+38+TAB_H, MX+MW, MY+38+TAB_H, C.border, 1))
    
    table.insert(drawings.frame, makeRect(MX, MY+MH-30, MW, 30, C.panel, true))
    table.insert(drawings.frame, makeLine(MX, MY+MH-30, MX+MW, MY+MH-30, C.border, 1))
    
    local pingTxt = makeTxt(MX+12, MY+MH-22, "Ping: --ms", C.textDim, 11)
    table.insert(drawings.frame, pingTxt)
    drawings.pingText = pingTxt
end

-- ================================================================================
--              CONTENT BUILDERS
-- ================================================================================
local contentY = 0
local CX, CW = 0, 0

local function addContent(d)
    table.insert(drawings.content, d)
    return d
end

local function contentStart()
    clearDrawings(drawings.content)
    drawings.content = {}
    contentDraws.toggles = {}
    contentDraws.keybinds = {}
    contentDraws.sliders = {}
    contentDraws.buttons = {}
    contentDraws.inputs = {}
    contentY = state.menuY + 38 + 32 + 10
    CX = state.menuX + 12
    CW = state.menuW - 24
end

local function nextY(h)
    local y = contentY
    contentY = contentY + (h or 26)
    return y
end

local function drawSection(label)
    local y = nextY(24)
    addContent(makeRect(CX-2, y-2, CW+4, 22, C.panelLight, true))
    addContent(makeRect(CX, y+3, 3, 12, C.accent, true))
    addContent(makeTxt(CX+10, y+2, label:upper(), C.accentHi, 12))
    nextY(4)
end

local function drawToggle(id, label, valKey, isState)
    local y = nextY(30)
    local val = isState and state[valKey] or cfg[valKey]
    
    addContent(makeRect(CX, y, CW, 28, C.panel, true))
    addContent(makeRect(CX, y, 3, 28, val and C.on or C.off, true))
    addContent(makeTxt(CX+12, y+7, label, C.text, 13))
    
    local switchX = CX + CW - 50
    addContent(makeRect(switchX, y+5, 44, 18, val and C.onDim or C.offDim, true))
    addContent(makeRect(switchX+2, y+7, 40, 14, C.panelLight, true))
    
    local dotX = val and (switchX+26) or (switchX+6)
    local dot = addContent(makeRect(dotX, y+9, 10, 10, val and C.on or C.off, true))
    
    contentDraws.toggles[id] = { dot = dot, valKey = valKey, x = CX, y = y, w = CW, h = 28, isState = isState or false }
end

local function drawKeybind(id, label, keyKey, nameKey)
    local y = nextY(30)
    
    addContent(makeRect(CX, y, CW, 28, C.panel, true))
    addContent(makeRect(CX, y, 3, 28, C.cyan, true))
    addContent(makeTxt(CX+12, y+7, label, C.text, 13))
    
    local btnW = 70
    local btnX = CX + CW - btnW - 6
    addContent(makeRect(btnX, y+4, btnW, 20, C.accentDim, true))
    addContent(makeRect(btnX+1, y+5, btnW-2, 18, C.panelLight, true))
    
    local keyName = cfg[nameKey] or "..."
    local val = addContent(makeTxt(btnX + btnW/2, y+7, "["..keyName.."]", C.accentHi, 12, true))
    
    contentDraws.keybinds[id] = { txt = val, keyKey = keyKey, nameKey = nameKey, x = CX, y = y, w = CW, h = 28 }
end

local function drawSlider(id, label, valKey, minV, maxV, suffix)
    local y = nextY(38)
    local val = cfg[valKey] or minV
    suffix = suffix or ""
    
    addContent(makeRect(CX, y, CW, 36, C.panel, true))
    addContent(makeRect(CX, y, 3, 36, C.yellow, true))
    addContent(makeTxt(CX+12, y+4, label, C.textDim, 11))
    local valTxt = addContent(makeTxt(CX+CW-12, y+4, val..suffix, C.yellow, 12))
    valTxt.Center = false
    
    local trackX = CX + 12
    local trackW = CW - 24
    local trackY = y + 22
    addContent(makeRect(trackX, trackY, trackW, 6, C.panelLight, true))
    
    local pct = (val - minV) / (maxV - minV)
    local fill = addContent(makeRect(trackX, trackY, math.max(6, trackW * pct), 6, C.accent, true))
    local thumb = addContent(makeRect(trackX + trackW * pct - 5, trackY - 2, 10, 10, C.accentHi, true))
    
    contentDraws.sliders[id] = {
        valKey = valKey, minV = minV, maxV = maxV, suffix = suffix,
        trackX = trackX, trackY = trackY, trackW = trackW,
        fill = fill, thumb = thumb, valTxt = valTxt,
        x = CX, y = y, w = CW, h = 36
    }
end

local function drawSpacing(h)
    nextY(h or 8)
end

-- ================================================================================
--              TAB CONTENT BUILDERS
-- ================================================================================
local function buildBoost()
    contentStart()
    
    drawSpacing(4)
    drawSection("Z Sanguine Boost")
    drawToggle("boost", "Enable Boost", "boostOn", false)
    drawSlider("boostSpeed", "Speed (X-Z)", "boostSpeed", 50, 1500, "")
    drawSlider("boostDur", "Duration", "boostDurMs", 1, 30, "")
    
    drawSpacing(4)
    drawSection("Flame Rocket Boost")
    drawToggle("flameBoost", "Enable Boost", "flameBoostOn", false)
    drawSlider("flameBoostSpeed", "Speed (X-Z)", "flameBoostSpeed", 50, 1500, "")
    drawSlider("flameBoostY", "Speed (Y Up)", "flameBoostY", 0, 100, "")
    drawSlider("flameBoostDur", "Duration", "flameBoostDurMs", 1, 30, "")
end

local function buildBlatant()
    contentStart()
    
    drawSpacing(4)
    drawSection("R+X Macro")
    drawKeybind("rxKey", "R+X", "rxKey", "rxKeyName")
    
    drawSpacing(4)
    drawSection("F-1-C Macro")
    drawKeybind("f1cKey", "F-1-C", "f1cKey", "f1cKeyName")
    drawSlider("f1cDelay1", "Delay F->1", "f1cDelay1", 0, 500, "ms")
    drawSlider("f1cDelay2", "Delay 1->C", "f1cDelay2", 0, 500, "ms")
    
    drawSpacing(4)
    drawSection("Desync Macro")
    drawKeybind("desyncKey", "Desync", "desyncKey", "desyncKeyName")
    drawSlider("desyncDelay1", "Delay Click->2", "desyncDelay1", 0, 500, "ms")
    drawSlider("desyncDelay2", "Delay 2->C", "desyncDelay2", 0, 500, "ms")
end

local function buildSettings()
    contentStart()
    
    drawSpacing(4)
    drawSection("Menu Settings")
    drawKeybind("menuKey", "Toggle Menu", "menuKey", "menuKeyName")
    
    drawSpacing(4)
    drawSection("Hotkey List")
    drawToggle("hkList", "Show List", "hkListShow", true)
    drawKeybind("hkListKey", "Toggle List", "hkListKey", "hkListKeyName")
    
    drawSpacing(10)
    drawSection("Instructions")
    
    local y = contentY
    addContent(makeRect(CX, y, CW, 90, C.panel, true))
    addContent(makeTxt(CX+12, y+8, ">> Drag to move", C.text, 11))
    addContent(makeTxt(CX+12, y+24, ">> Drag corner to resize", C.text, 11))
    addContent(makeTxt(CX+12, y+40, ">> Click keybinds to rebind", C.text, 11))
    addContent(makeTxt(CX+12, y+56, ">> G = R+X | H = F-1-C", C.text, 11))
    addContent(makeTxt(CX+12, y+72, ">> V = Desync | F5 = HK List", C.yellow, 11))
    nextY(90)
end

local tabBuilders = { buildBoost, buildBlatant, buildSettings }

-- ================================================================================
--              MOUSE HELPERS
-- ================================================================================
local mouse = player:GetMouse()
local mouseX, mouseY = 0, 0

local function updateMouse()
    mouseX = mouse.X
    mouseY = mouse.Y
end

local function inBox(mx, my, x, y, w, h)
    return mx >= x and mx <= x+w and my >= y and my <= y+h
end

-- ================================================================================
--              MACROS EXECUTION
-- ================================================================================
local function fireRX()
    keypress(0x52)
    task.wait(0.05)
    keypress(0x58)
    task.wait(0.05)
    keyrelease(0x52)
    task.wait(0.05)
    keyrelease(0x58)
end

local function fireF1C()
    keypress(0x46)
    task.wait(0.01)
    keyrelease(0x46)
    task.wait(cfg.f1cDelay1 / 1000)
    keypress(0x31)
    task.wait(0.01)
    keyrelease(0x31)
    task.wait(cfg.f1cDelay2 / 1000)
    keypress(0x43)
    task.wait(0.01)
    keyrelease(0x43)
end

local function fireDesync()
    mouse1press()
    task.wait(0.01)
    mouse1release()
    task.wait(cfg.desyncDelay1 / 1000)
    
    keypress(0x32)
    task.wait(0.01)
    keyrelease(0x32)
    task.wait(cfg.desyncDelay2 / 1000)
    
    keypress(0x43)
    task.wait(0.01)
    keyrelease(0x43)
end

-- ================================================================================
--              Z BOOST
-- ================================================================================
runService.Heartbeat:Connect(function()
    local char = player.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local zFire = root:FindFirstChild("SanguineArtZFire") ~= nil

    if cfg.boostOn and zFire and not state.wasZFire and not state.boosting then
        state.boosting = true
        local spd = cfg.boostSpeed
        local dur = (cfg.boostDurMs or 3) / 10
        local lv  = root.CFrame.LookVector
        task.spawn(function()
            local t = os.clock() + dur
            while os.clock() < t do
                local c = player.Character
                if not c then break end
                local r = c:FindFirstChild("HumanoidRootPart")
                if not r then break end
                r.AssemblyLinearVelocity = Vector3.new(lv.X * spd, lv.Y * spd, lv.Z * spd)
                task.wait()
            end
            state.boosting = false
        end)
    end
    state.wasZFire = zFire
end)

-- ================================================================================
--              FLAME BOOST (3D)
-- ================================================================================
local lastFlameBoostTime = 0

runService.Heartbeat:Connect(function()
    local char = player.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local flameTool = char:FindFirstChild("Flame-Flame")
    if not flameTool then return end
    
    local holdingValue = flameTool:FindFirstChild("Holding")
    if not holdingValue then return end
    
    if holdingValue.Value and cfg.flameBoostOn then
        local now = os.clock() * 1000
        
        if (now - lastFlameBoostTime) > 500 then
            state.flameBoosting = true
            local spd = cfg.flameBoostSpeed
            local upForce = cfg.flameBoostY
            local dur = (cfg.flameBoostDurMs or 5) / 10
            
            local lv = root.CFrame.LookVector
            local velocityX = lv.X * spd
            local velocityZ = lv.Z * spd
            local velocityY = upForce * 5
            
            local finalVelocity = Vector3.new(velocityX, velocityY, velocityZ)
            
            task.spawn(function()
                local t = os.clock() + dur
                while os.clock() < t do
                    local c = player.Character
                    if not c then break end
                    local r = c:FindFirstChild("HumanoidRootPart")
                    if not r then break end
                    r.AssemblyLinearVelocity = finalVelocity
                    task.wait()
                end
                state.flameBoosting = false
            end)
            
            lastFlameBoostTime = now
        end
    end
end)

-- ================================================================================
--              PING UPDATE
-- ================================================================================
task.spawn(function()
    while true do
        pcall(function()
            local ok, p = pcall(GetPingValue)
            if ok and drawings.pingText then
                drawings.pingText.Text = "Ping: " .. tostring(p) .. "ms"
                drawings.pingText.Color = p < 80 and C.on or (p < 150 and C.yellow or C.off)
            end
        end)
        task.wait(1)
    end
end)

-- ================================================================================
--              HOTKEY LIST OVERLAY
-- ================================================================================
local function buildHotkeyList()
    clearDrawings(drawings.hkList)
    drawings.hkList = {}
    
    if not state.hkListShow then return end

    local entries = {
        { label = "Z Boost",    key = cfg.boostKeyName or getKeyName(cfg.boostKey) },
        { label = "Flame Boost",  key = "Auto" },
        { label = "R+X Macro",  key = cfg.rxKeyName    or getKeyName(cfg.rxKey) },
        { label = "F-1-C",      key = cfg.f1cKeyName   or getKeyName(cfg.f1cKey) },
        { label = "Desync",     key = cfg.desyncKeyName or getKeyName(cfg.desyncKey) },
        { label = "Menu",       key = cfg.menuKeyName  or getKeyName(cfg.menuKey) },
        { label = "HK List",    key = cfg.hkListKeyName or getKeyName(cfg.hkListKey) },
    }

    local HX  = hkState.x
    local HY  = hkState.y
    local HW  = hkState.w
    local ROW = math.clamp(math.floor(HW / 10), 18, 26)
    local fontSize = math.clamp(math.floor(HW / 19), 9, 13)
    local HH  = 30 + #entries * ROW + 6

    local function ins(d) table.insert(drawings.hkList, d) end

    ins(makeRect(HX+3, HY+3, HW, HH, Color3.fromRGB(0,0,0), true, 0.7))
    ins(makeRect(HX-1, HY-1, HW+2, HH+2, C.borderHi, true))
    ins(makeRect(HX, HY, HW, HH, C.bg, true, 0.95))
    ins(makeRect(HX, HY, HW, 3, C.accent, true))
    ins(makeRect(HX, HY, HW, 28, C.topbar, true))
    ins(makeTxt(HX + HW/2, HY + 8, "KEYBIND LIST", C.white, 13, true))
    ins(makeRect(HX, HY+28, HW, 1, C.border, true))

    for i, entry in ipairs(entries) do
        local ry = HY + 30 + (i-1) * ROW
        ins(makeRect(HX+4, ry+1, HW-8, ROW-2, C.panel, true))
        ins(makeRect(HX+4, ry+1, 3, ROW-2, C.cyan, true))
        ins(makeTxt(HX+12, ry + math.floor(ROW/2) - 6, entry.label, C.text, fontSize))

        local badgeW = math.max(32, math.floor(HW * 0.22))
        local badgeX = HX + HW - badgeW - 6
        ins(makeRect(badgeX, ry+3, badgeW, ROW-6, C.accentDim, true))
        ins(makeTxt(badgeX + badgeW/2, ry + math.floor(ROW/2) - 6, "["..entry.key.."]", C.accentHi, fontSize, true))
    end

    ins(makeRect(HX+HW-14, HY+HH-14, 10, 2, C.borderHi, true))
    ins(makeRect(HX+HW-10, HY+HH-10, 6,  2, C.borderHi, true))
end

local function switchTab(idx)
    state.currentTab = idx
    rebuildMenu()
    tabBuilders[idx]()
end

local wasMB1 = false
local activeSlider = nil
local lastRebuildTime = 0

rebuildMenu()
switchTab(1)
buildHotkeyList()

-- ================================================================================
--              MAIN INPUT LOOP
-- ================================================================================
task.spawn(function()
    while true do
        updateMouse()
        
        local mb1 = ismouse1pressed()
        local mb1tap = mb1 and not wasMB1
        wasMB1 = mb1
        
        if state.editingInputValKey then
            local inputChanged = false
            
            if iskeypressed(0x08) and not wasKeys[0x08] then
                state.inputBuffer = string.sub(state.inputBuffer, 1, #state.inputBuffer - 1)
                wasKeys[0x08] = true
                inputChanged = true
            elseif iskeypressed(0x0D) and not wasKeys[0x0D] then
                if state.inputBuffer ~= "" then
                    local numVal = tonumber(state.inputBuffer)
                    if numVal then
                        cfg[state.editingInputValKey] = numVal
                    else
                        cfg[state.editingInputValKey] = state.inputBuffer
                    end
                end
                wasKeys[0x0D] = true
                inputChanged = true
            elseif iskeypressed(0x1B) and not wasKeys[0x1B] then
                state.editingInputValKey = nil
                state.inputBuffer = ""
                wasKeys[0x1B] = true
                inputChanged = true
            else
                for vk, char in pairs(VK_CHARS) do
                    if iskeypressed(vk) and not wasKeys[vk] then
                        if #state.inputBuffer < 10 then
                            state.inputBuffer = state.inputBuffer .. char
                            wasKeys[vk] = true
                            inputChanged = true
                        end
                        break
                    end
                end
            end
            
            if inputChanged then
                rebuildMenu()
                tabBuilders[state.currentTab]()
            end
            
            task.wait(0.02)
            continue
        end
        
        for vk, _ in pairs(VK_NAMES) do
            if not iskeypressed(vk) then
                wasKeys[vk] = false
            end
        end
        
        for vk, _ in pairs(VK_CHARS) do
            if not iskeypressed(vk) then
                wasKeys[vk] = false
            end
        end
        
        for vk, name in pairs(VK_NAMES) do
            local isPressed = iskeypressed(vk)
            if isPressed and not wasKeys[vk] then
                if vk == cfg.menuKey then
                    state.menuVisible = not state.menuVisible
                    for _, d in pairs(drawings.frame) do d.Visible = state.menuVisible end
                    for _, d in pairs(drawings.content) do d.Visible = state.menuVisible end
                    wasKeys[vk] = true
                elseif vk == cfg.hkListKey then
                    state.hkListShow = not state.hkListShow
                    buildHotkeyList()
                    rebuildMenu()
                    tabBuilders[state.currentTab]()
                    wasKeys[vk] = true
                elseif vk == cfg.rxKey then
                    task.spawn(fireRX)
                    wasKeys[vk] = true
                elseif vk == cfg.f1cKey then
                    task.spawn(fireF1C)
                    wasKeys[vk] = true
                elseif vk == cfg.desyncKey then
                    task.spawn(fireDesync)
                    wasKeys[vk] = true
                end
            end
        end
        
        if not state.menuVisible then
            task.wait(0.02)
            continue
        end
        
        local MX, MY = state.menuX, state.menuY
        local MW, MH = state.menuW, state.menuH
        
        if state.bindingTarget then
            if iskeypressed(0x1B) then
                state.bindingTarget = nil
                tabBuilders[state.currentTab]()
            else
                local vk, name = detectKeyboardKey()
                if vk then
                    local t = state.bindingTarget
                    cfg[t.keyKey] = vk
                    cfg[t.nameKey] = name or getKeyName(vk)
                    state.bindingTarget = nil
                    tabBuilders[state.currentTab]()
                    buildHotkeyList()
                end
            end
        end
        
        if mb1 then
            if state.dragging then
                state.menuX = math.max(0, mouseX - state.dragOffsetX)
                state.menuY = math.max(0, mouseY - state.dragOffsetY)
            elseif state.resizing then
                state.menuW = math.max(state.minW, mouseX - state.menuX + state.resizeOffsetX)
                state.menuH = math.max(state.minH, mouseY - state.menuY + state.resizeOffsetY)
            elseif mb1tap then
                if inBox(mouseX, mouseY, MX+MW-24, MY+MH-24, 24, 24) then
                    state.resizing = true
                    state.resizeOffsetX = MX + MW - mouseX
                    state.resizeOffsetY = MY + MH - mouseY
                elseif inBox(mouseX, mouseY, MX, MY, MW, 38) then
                    state.dragging = true
                    state.dragOffsetX = mouseX - MX
                    state.dragOffsetY = mouseY - MY
                end
            end
        else
            state.dragging = false
            state.resizing = false
        end
        
        if mb1tap then
            local TAB_H = 32
            local tabY0 = MY + 38
            local tabY1 = MY + 38 + TAB_H
            if mouseY >= tabY0 and mouseY <= tabY1 and mouseX >= MX and mouseX <= MX+MW then
                local TABS = {"Boost", "Blatant", "Settings"}
                local TAB_W = MW / #TABS
                local rel = mouseX - MX
                local idx = math.floor(rel / TAB_W) + 1
                if idx >= 1 and idx <= #TABS then
                    switchTab(idx)
                end
            end
            
            for id, obj in pairs(contentDraws.toggles) do
                if inBox(mouseX, mouseY, obj.x, obj.y, obj.w, obj.h) then
                    if obj.isState then
                        state[obj.valKey] = not state[obj.valKey]
                        buildHotkeyList()
                    else
                        cfg[obj.valKey] = not cfg[obj.valKey]
                    end
                    rebuildMenu()
                    tabBuilders[state.currentTab]()
                end
            end
            
            for id, obj in pairs(contentDraws.keybinds) do
                if inBox(mouseX, mouseY, obj.x, obj.y, obj.w, obj.h) then
                    state.bindingTarget = obj
                    obj.txt.Text = "[...]"
                    obj.txt.Color = C.yellow
                end
            end
            
            for id, obj in pairs(contentDraws.sliders) do
                if inBox(mouseX, mouseY, obj.trackX, obj.trackY-4, obj.trackW, 12) then
                    activeSlider = obj
                end
            end
        end
        
        if mb1 and activeSlider then
            local obj = activeSlider
            local rel = math.clamp(mouseX - obj.trackX, 0, obj.trackW)
            local pct = rel / obj.trackW
            local val = math.floor(obj.minV + pct * (obj.maxV - obj.minV))
            cfg[obj.valKey] = val
            obj.valTxt.Text = tostring(val)..(obj.suffix or "")
            local fw = math.max(6, obj.trackW * pct)
            obj.fill.Size = Vector2.new(fw, 6)
            obj.thumb.Position = Vector2.new(obj.trackX + obj.trackW * pct - 5, obj.trackY - 2)
        elseif not mb1 then
            activeSlider = nil
        end
        
        local now = os.clock()
        if (state.dragging or state.resizing) and (now - lastRebuildTime > 0.05) then
            rebuildMenu()
            tabBuilders[state.currentTab]()
            lastRebuildTime = now
        end
        
        task.wait(0.02)
    end
end)

notify("EXO HUB", "Toggle Fixed - dc: ktavex_", 3)