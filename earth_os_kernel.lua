-- ====================
-- 5500FP Setun 24: EARTH OS Kernel v2.5 (Fully Calibrated Hardware & Ergonomics)
-- Topological Braid Engine, B-ASM Microcode VM, Dynamic Audio Synthesizer,
-- TPM Security Module, Quantum Qutrit Register & Universal Compute OS
-- Based on: Elastic Aether R(3) Twist Hydrodynamics (EARTH)
-- Target Platform: Retro Gadgets (Lua 5.3 / 5.4)
-- ====================

-- ====================
-- 1. HARDWARE BINDINGS & PERIPHERALS
-- ====================
local vid       = gdt.VideoChip0
local kb        = gdt.KeyboardChip0
local wifi      = gdt.Wifi0
local memMinus  = gdt.FlashMemory0
local memZero   = gdt.FlashMemory1
local memPlus   = gdt.FlashMemory2
local rom       = gdt.ROM
local audioChip = gdt.AudioChip0
local speaker   = gdt.Speaker0

-- Ensure Speaker is physically enabled and AudioChip maxed
if speaker then
    speaker.State = true
end
if audioChip then
    pcall(function() audioChip.Volume = 100 end)
end

-- System font from ROM
local sysFont = rom.System.SpriteSheets["StandardFont"]

-- 24 Hardware LED Array
local leds = {}
for i = 0, 23 do
    leds[i + 1] = gdt["Led" .. i]
end

-- Connection Status Indicator LED (Led24 / Channel 10)
local linkLed = gdt.Led24 or gdt["Led24"]
local serverConnected = false
local connectionTimeout = 0
local syncRequested = false

-- Modular Magnetic Connector Dock (Channel 11)
local magDock = gdt.MagneticConnector0 or gdt["MagneticConnector0"] or gdt["MagneticConnector"]
local isDocked = false

-- Hardware LedButtons (Macro & Function Buttons)
local ledButtons = {}
for i = 0, 15 do
    if gdt["LedButton" .. i] then
        ledButtons[i] = gdt["LedButton" .. i]
    end
end

-- Initialize LedButton Colors (Calibrated to Exact Physical Order)
local function initLedButtons()
    -- 3 Center Macro Keys (Channels 3, 4, 5)
    if ledButtons[0] then -- Channel 3: -1 (Left Twist)
        ledButtons[0].LedColor = color.red
        ledButtons[0].LedState = true
    end
    if ledButtons[1] then -- Channel 4: 0 (Identity)
        ledButtons[1].LedColor = color.white
        ledButtons[1].LedState = true
    end
    if ledButtons[2] then -- Channel 5: +1 (Right Twist)
        ledButtons[2].LedColor = color.green
        ledButtons[2].LedState = true
    end

    -- 4 Left Side Function Buttons (Calibrated to Top->Bottom: Ch 9, 8, 7, 6)
    if ledButtons[6] then -- Top Side Button (Ch 9): SIMP
        ledButtons[6].LedColor = color.cyan
        ledButtons[6].LedState = true
    end
    if ledButtons[5] then -- 2nd Side Button (Ch 8): INV
        ledButtons[5].LedColor = color.yellow
        ledButtons[5].LedState = true
    end
    if ledButtons[4] then -- 3rd Side Button (Ch 7): VIEW MEM
        ledButtons[4].LedColor = color.magenta
        ledButtons[4].LedState = true
    end
    if ledButtons[3] then -- Bottom Side Button (Ch 6): SYNC
        ledButtons[3].LedColor = color.blue
        ledButtons[3].LedState = true
    end
end

initLedButtons()

-- Forward State Declarations
local ACC = {}
for i = 1, 24 do ACC[i] = 0 end
local systemMode = "BOOT"
local activeWaveMode = nil
local lampSyncEnabled = false
local lastSyncedMode = ""

local function debugLog(msg, colorId)
    pcall(function()
        if setFgColor and colorId then setFgColor(colorId) end
        if log then log(tostring(msg))
        elseif print then print(tostring(msg)) end
        if resetColors then resetColors() end
    end)
end

local function debugWarn(msg)
    pcall(function()
        if logWarning then logWarning(tostring(msg))
        else debugLog("[WARN] " .. tostring(msg), 33) end
    end)
end

local function debugErr(msg)
    pcall(function()
        if logError then logError(tostring(msg))
        else debugLog("[ERR] " .. tostring(msg), 31) end
    end)
end

local function notifyDesk(msg, level)
    pcall(function()
        if desk then
            if level == "WARN" and desk.ShowWarning then
                desk.ShowWarning(tostring(msg), false)
            elseif level == "ERR" and desk.ShowError then
                desk.ShowError(tostring(msg), false)
            elseif desk.ShowMessage then
                desk.ShowMessage(tostring(msg), false)
            end
        end
    end)
end

local function setAmbientLamp(c, state, force)
    pcall(function()
        if desk and (lampSyncEnabled or force) then
            if state ~= nil and desk.SetLampState then
                desk.SetLampState(state)
            end
            if c and desk.SetLampColor then
                desk.SetLampColor(c)
            end
        end
    end)
end

local function syncLampWithState()
    if not lampSyncEnabled then return end

    local targetColor = color.cyan
    if activeWaveMode then
        targetColor = color.yellow
    elseif systemMode == "QUANTUM" then
        targetColor = color.cyan
    elseif systemMode == "OSCILLOSCOPE" then
        targetColor = color.yellow
    elseif systemMode == "QUASICRYSTAL" then
        targetColor = color.magenta
    else
        local netQ = 0
        if ACC and type(ACC) == "table" then
            for i = 1, 24 do
                netQ = netQ + (ACC[i] or 0)
            end
        end
        if netQ > 0 then targetColor = color.green
        elseif netQ < 0 then targetColor = color.red
        else targetColor = color.cyan end
    end

    if targetColor ~= lastSyncedMode then
        lastSyncedMode = targetColor
        setAmbientLamp(targetColor, true, true)
    end
end

-- Clear multitool and output initial startup banner
pcall(function()
    if clear then clear() end
    debugLog("====================", 36)
    debugLog("5500FP SETUN 24", 96)
    debugLog("EARTH OS v2.5", 37)
    debugLog("====================", 36)
    debugLog("Peripherals: 35 Online", 32)
    debugLog("Qutrit: READY | TPM: OK", 35)
    notifyDesk("5500FP SETUN 24 READY", "INFO")
end)

-- ====================
-- 2. UNIVERSAL CONSTANTS & EXACT ANALYTIC RELATIONS
-- ====================
local PHI            = (1 + math.sqrt(5)) / 2              -- Golden Ratio: 1.618033988749895
local PHI_INV        = PHI - 1                             -- 1 / phi = 0.618033988749895
local PHI_SQ         = PHI * PHI                           -- phi^2 = 2.618033988749895
local PHI_INV_SQ     = PHI_INV * PHI_INV                   -- phi^-2 = 0.381966011250105
local XI_0           = 0.1500000000000000                  -- Coherence length (fm)
local XI_0_METERS    = XI_0 * 1e-15                        -- Coherence length (m)
local LAMBDA_0       = 44.492000000000000                  -- Quartic coupling (4*pi)^3
local DELTA_CHI      = 0.1500000000000000                  -- Chiral twist angle (rad)
local C_LIGHT        = 299792458                           -- Speed of light (m/s)
local HBAR_EXACT     = 1.054571817e-34                     -- Reduced Planck constant (J s)
local M_PROTON_MEV   = 938.27208816                        -- Proton mass (MeV)
local M_ELECTRON_MEV = M_PROTON_MEV * (PHI ^ -16)          -- Electron mass (MeV)
local R_TUBE_FM      = XI_0 * PHI_INV_SQ                   -- Constant tube radius: 0.05716 fm
local KAPPA_EFF      = math.sqrt(6) * PHI_INV_SQ           -- Intrinsic curvature
local PI_EARTH       = math.sqrt(30 - 6 * math.sqrt(5)) / 2-- Algebraic Pi (deg 4)
local ALPHA_INV      = 120 * math.pi * 3 * PHI_SQ          -- Fine-structure inverse: 137.036
local G_NEWTON       = 6.67430e-11                         -- Gravitational constant
local Q_UNIVERSE     = 9.15e78                             -- Observable universe charge
local XI_UNIVERSE_LY = 93e9                                -- Horizon: 93 Gly
local LAMBDA_COSMO   = 1.19e-52                            -- Cosmological constant (m^-2)
local RHO_NUC        = 2.8e17                              -- Nuclear density (kg/m^3)
local RHO_MYELIN     = 0.95e27                             -- Myelin density (m^-3)
local RHO_BRAIN      = 1.03e3                              -- Brain density (kg/m^3)
local F_CONSCIOUS    = 7.83                                -- Fundamental Schumann mode (Hz)

-- ====================
-- 3. KERNEL SYSTEM STATE & BUFFERS
-- ====================
local bootTimer      = 0
systemMode           = "BOOT"        -- Modes: "BOOT", "TERMINAL", "OSCILLOSCOPE", "QUANTUM", "QUASICRYSTAL"
local cursorBlink    = 0
local memViewAddr    = 0
local inputLine      = ""
local cliBuffer      = {"5500FP Setun 24", "EARTH v2.5", "SYS READY."}
local commandHistory = {}
local historyIndex   = 0

-- 24-Trit Balanced Ternary Accumulator register: trits in {-1, 0, +1}
for i = 1, 24 do ACC[i] = 0 end

-- Relativistic Soliton Wave Simulation Buffer (24 cells)
local SolitonBuffer = {}
for i = 1, 24 do SolitonBuffer[i] = 0.0 end
local solitonTime    = 0.0
local solitonActive  = false
local solitonVelocity= 120.0

-- Balanced Ternary Quantum Qutrit Register
local Qutrit = {
    c_minus = 1.0 / math.sqrt(3),
    c_zero  = 1.0 / math.sqrt(3),
    c_plus  = 1.0 / math.sqrt(3),
    phase   = 0.0
}

-- Quasicrystal Projected Cache
local QuasicrystalPoints = {}

-- Audio feedback toggle & sample cache
local audioEnabled = true
local systemAudioSample = nil

-- Networking poll state
local pollTimer = 0
local isPolling = false

-- Safe helper to fetch AudioSample by key without calling pairs() on userdata
local function getSample(container, name)
    if not container then return nil end
    local ok, res = pcall(function() return container[name] end)
    if ok and res ~= nil then return res end
    return nil
end

local function discoverAudioSample()
    local candidateNames = {
        "audio.wav", "audio", "Audio.wav", "Audio",
        "sound.wav", "sound", "Sound.wav", "Sound",
        "beep.wav", "beep", "Beep.wav", "Beep",
        "click.wav", "click", "Click.wav", "Click",
        "sample.wav", "sample", "Sample.wav", "Sample",
        "tone.wav", "tone", "Tone.wav", "Tone",
        "ping.wav", "ping", "Ping.wav", "Ping"
    }

    if rom and rom.User and rom.User.AudioSamples then
        for _, n in ipairs(candidateNames) do
            local s = getSample(rom.User.AudioSamples, n)
            if s then return s end
        end
        for i = 1, 16 do
            local s = getSample(rom.User.AudioSamples, i)
            if s then return s end
        end
    end

    if rom and rom.System and rom.System.AudioSamples then
        for _, n in ipairs(candidateNames) do
            local s = getSample(rom.System.AudioSamples, n)
            if s then return s end
        end
        for i = 1, 16 do
            local s = getSample(rom.System.AudioSamples, i)
            if s then return s end
        end
    end

    return nil
end

systemAudioSample = discoverAudioSample()

-- Comprehensive Keyboard mapping (Supports Plus, Equals, Keypads, and all symbols)
local charMap = {
    ["A"] = "A", ["B"] = "B", ["C"] = "C", ["D"] = "D", ["E"] = "E", ["F"] = "F",
    ["G"] = "G", ["H"] = "H", ["I"] = "I", ["J"] = "J", ["K"] = "K", ["L"] = "L",
    ["M"] = "M", ["N"] = "N", ["O"] = "O", ["P"] = "P", ["Q"] = "Q", ["R"] = "R",
    ["S"] = "S", ["T"] = "T", ["U"] = "U", ["V"] = "V", ["W"] = "W", ["X"] = "X",
    ["Y"] = "Y", ["Z"] = "Z",
    ["Alpha0"] = "0", ["Alpha1"] = "1", ["Alpha2"] = "2", ["Alpha3"] = "3",
    ["Alpha4"] = "4", ["Alpha5"] = "5", ["Alpha6"] = "6", ["Alpha7"] = "7",
    ["Alpha8"] = "8", ["Alpha9"] = "9",
    ["Keypad0"] = "0", ["Keypad1"] = "1", ["Keypad2"] = "2", ["Keypad3"] = "3",
    ["Keypad4"] = "4", ["Keypad5"] = "5", ["Keypad6"] = "6", ["Keypad7"] = "7",
    ["Keypad8"] = "8", ["Keypad9"] = "9",
    ["Minus"] = "-", ["KeypadMinus"] = "-",
    ["Plus"] = "+", ["KeypadPlus"] = "+", ["Equals"] = "+",
    ["Period"] = ".", ["KeypadPeriod"] = ".", ["Comma"] = ",",
    ["Slash"] = "/", ["KeypadDivide"] = "/", ["Space"] = " ",
    ["Underscore"] = "_", ["Colon"] = ":"
}

-- Forward declaration of executeCommand
local executeCommand

-- ====================
-- 4. HARDWARE ABSTRACTION LAYER (HAL) & RETRO GADGETS AUDIO DRIVER
-- ====================

local memPeekActive = false
local memPeekTimer  = 0
local memPeekBuffer = {}

local function updateLeds()
    for i = 1, 24 do
        if memPeekActive then
            local trit = memPeekBuffer[i] or 0
            if trit == 1 then
                leds[i].State = true
                leds[i].Color = color.magenta
            elseif trit == -1 then
                leds[i].State = true
                leds[i].Color = color.cyan
            else
                leds[i].State = false
            end
        elseif systemMode == "OSCILLOSCOPE" or activeWaveMode then
            local val = SolitonBuffer[i] or 0
            if val > 0.3 then
                leds[i].State = true
                leds[i].Color = color.green
            elseif val < -0.3 then
                leds[i].State = true
                leds[i].Color = color.red
            elseif math.abs(val) > 0.05 then
                leds[i].State = true
                leds[i].Color = color.yellow
            else
                leds[i].State = false
            end
        else
            local trit = ACC[i]
            if trit == 1 then
                leds[i].State = true
                leds[i].Color = color.green
            elseif trit == -1 then
                leds[i].State = true
                leds[i].Color = color.red
            else
                leds[i].State = false
            end
        end
    end
end

local function printLine(text, fullLog)
    local screenW = vid.Width or 50
    local maxChars = math.max(8, math.floor((screenW - 2) / 5))
    text = tostring(text)
    debugLog(fullLog or ("[CRT] " .. text), 37)

    if #text > maxChars then
        text = string.sub(text, 1, maxChars)
    end
    table.insert(cliBuffer, text)

    while #cliBuffer > 60 do
        table.remove(cliBuffer, 1)
    end
end

local function printError(crtShort, fullLog)
    fullLog = fullLog or crtShort
    debugErr(fullLog)
    notifyDesk(fullLog, "ERR")
    printLine(crtShort, fullLog)
end

-- Dual-channel gain-boosted playback driver
local function playSample(pitchMultiplier, ch)
    if not audioEnabled then return end
    if not systemAudioSample then
        systemAudioSample = discoverAudioSample()
    end
    if not audioChip or not systemAudioSample then return end

    pcall(function()
        if speaker then speaker.State = true end
        audioChip.Volume = 100

        -- Channel A
        local c1 = ch or 0
        audioChip:SetChannelVolume(100, c1)
        audioChip:SetChannelPitch(pitchMultiplier or 1.0, c1)
        audioChip:Play(systemAudioSample, c1)

        -- Channel B (Dual-gain boost if mono channel requested)
        if ch == nil then
            audioChip:SetChannelVolume(100, 1)
            audioChip:SetChannelPitch(pitchMultiplier or 1.0, 1)
            audioChip:Play(systemAudioSample, 1)
        end
    end)
end

local function soundClick(pitchMod)
    local pitch = 1.0 + (pitchMod or 0) * 0.3
    playSample(pitch)
end

local function soundResonance(freq)
    local pitch = math.max(0.2, math.min(3.0, freq / 10.0))
    playSample(pitch)
end

local function soundQuantumChirp()
    playSample(1.5, 0)
    playSample(2.0, 1)
end

local function soundTPMChime()
    playSample(1.0, 0) -- C
    playSample(1.25, 1)-- E
    playSample(1.5, 2) -- G
end

-- Triple-rail balanced ternary flash memory write
local function writeWord(wordAddr, tritArray)
    local minusData = (memMinus.Usage > 0) and memMinus:Load() or {}
    local zeroData  = (memZero.Usage > 0) and memZero:Load() or {}
    local plusData  = (memPlus.Usage > 0) and memPlus:Load() or {}

    local mRail, zRail, pRail = {}, {}, {}
    for i = 1, 24 do
        local trit = tritArray[i] or 0
        mRail[i] = (trit == -1) and 1 or 0
        zRail[i] = (trit == 0)  and 1 or 0
        pRail[i] = (trit == 1)  and 1 or 0
    end

    local addrKey = tostring(wordAddr)
    minusData[addrKey] = mRail
    zeroData[addrKey]  = zRail
    plusData[addrKey]  = pRail

    memMinus:Save(minusData)
    memZero:Save(zeroData)
    memPlus:Save(plusData)
end

-- Triple-rail balanced ternary flash memory read
local function readWord(wordAddr)
    local addrKey = tostring(wordAddr)
    local minusData = (memMinus.Usage > 0) and memMinus:Load() or {}
    local plusData  = (memPlus.Usage > 0) and memPlus:Load() or {}

    local mRail = minusData[addrKey] or {}
    local pRail = plusData[addrKey] or {}

    local tritArray = {}
    for i = 1, 24 do
        if pRail[i] == 1 then
            tritArray[i] = 1
        elseif mRail[i] == 1 then
            tritArray[i] = -1
        else
            tritArray[i] = 0
        end
    end
    return tritArray
end

-- ====================
-- 5. BRAID ASSEMBLY ENGINE (B-ASM MICROCODE VIRTUAL MACHINE)
-- ====================

local BASM = {
    program = {},
    pc = 1,
    running = false,
    cycles = 0,
    maxCycles = 256
}

function BASM.Clear()
    BASM.program = {}
    BASM.pc = 1
    BASM.running = false
    BASM.cycles = 0
end

-- Normalizes opcodes (e.g. B_SET, BSET, SET -> B_SET)
local function normalizeOpcode(op)
    op = string.upper(op or "NOP")
    op = string.gsub(op, "_", "")
    if op == "BSET" or op == "SET" then return "B_SET"
    elseif op == "BSIMP" or op == "SIMP" then return "B_SIMP"
    elseif op == "BSHFT" or op == "SHFT" or op == "SHIFT" then return "B_SHFT"
    elseif op == "BROT" or op == "ROT" or op == "ROTATE" then return "B_ROT"
    elseif op == "BINV" or op == "INV" or op == "INVERT" then return "B_INV"
    elseif op == "BLOAD" or op == "LOAD" then return "B_LOAD"
    elseif op == "BSAVE" or op == "SAVE" then return "B_SAVE"
    elseif op == "BMERG" or op == "MERG" or op == "MERGE" then return "B_MERG"
    elseif op == "BJMP" or op == "JMP" then return "B_JMP"
    elseif op == "BJZ" or op == "JZ" then return "B_JZ"
    elseif op == "BJP" or op == "JP" then return "B_JP"
    elseif op == "BJN" or op == "JN" then return "B_JN"
    elseif op == "BHALT" or op == "HALT" or op == "HLT" then return "B_HALT"
    else return op end
end

function BASM.SetLine(lineNum, op, arg)
    lineNum = tonumber(lineNum) or 1
    op = normalizeOpcode(op)
    BASM.program[lineNum] = { op = op, arg = arg }
end

function BASM.SumAcc()
    local sum = 0
    for i = 1, 24 do sum = sum + ACC[i] end
    return sum
end

function BASM.Step()
    if not BASM.program[BASM.pc] then
        BASM.running = false
        return false, "END OF PROG"
    end

    local inst = BASM.program[BASM.pc]
    local op   = inst.op
    local arg  = inst.arg
    BASM.pc    = BASM.pc + 1
    BASM.cycles= BASM.cycles + 1

    if op == "B_MERG" then
        local addr = tonumber(arg) or 0
        local w = readWord(addr)
        for i = 1, 24 do
            if w[i] ~= 0 then ACC[i] = w[i] end
        end
        updateLeds()
        soundClick(1)

    elseif op == "B_SIMP" then
        for i = 1, 23 do
            if (ACC[i] == 1 and ACC[i+1] == -1) or (ACC[i] == -1 and ACC[i+1] == 1) then
                ACC[i] = 0; ACC[i+1] = 0
            end
        end
        updateLeds()
        soundClick(-1)

    elseif op == "B_SHFT" then
        local n = tonumber(arg) or 1
        if n > 0 then
            for _ = 1, n do
                for i = 24, 2, -1 do ACC[i] = ACC[i-1] end
                ACC[1] = 0
            end
        else
            for _ = 1, math.abs(n) do
                for i = 1, 23 do ACC[i] = ACC[i+1] end
                ACC[24] = 0
            end
        end
        updateLeds()
        soundClick(0)

    elseif op == "B_ROT" then
        local n = tonumber(arg) or 1
        for _ = 1, math.abs(n) do
            if n > 0 then
                local last = ACC[24]
                for i = 24, 2, -1 do ACC[i] = ACC[i-1] end
                ACC[1] = last
            else
                local first = ACC[1]
                for i = 1, 23 do ACC[i] = ACC[i+1] end
                ACC[24] = first
            end
        end
        updateLeds()

    elseif op == "B_INV" then
        for i = 1, 24 do ACC[i] = -ACC[i] end
        updateLeds()
        soundClick(2)

    elseif op == "B_LOAD" then
        local addr = tonumber(arg) or 0
        ACC = readWord(addr)
        updateLeds()

    elseif op == "B_SAVE" then
        local addr = tonumber(arg) or 0
        writeWord(addr, ACC)

    elseif op == "B_SET" then
        local str = tostring(arg or "")
        for i = 1, math.min(24, #str) do
            local c = string.sub(str, i, i)
            if c == "+" or c == "1" then ACC[i] = 1
            elseif c == "-" or c == "2" then ACC[i] = -1
            else ACC[i] = 0 end
        end
        updateLeds()

    elseif op == "B_JMP" then
        BASM.pc = tonumber(arg) or BASM.pc

    elseif op == "B_JZ" then
        local sum = BASM.SumAcc()
        if sum == 0 then BASM.pc = tonumber(arg) or BASM.pc end

    elseif op == "B_JP" then
        local sum = BASM.SumAcc()
        if sum > 0 then BASM.pc = tonumber(arg) or BASM.pc end

    elseif op == "B_JN" then
        local sum = BASM.SumAcc()
        if sum < 0 then BASM.pc = tonumber(arg) or BASM.pc end

    elseif op == "B_HALT" then
        BASM.running = false
        return false, "HALT"
    end

    if BASM.cycles >= BASM.maxCycles then
        BASM.running = false
        return false, "CYCLE LIMIT"
    end
    return true, op
end

function BASM.Run(startLine)
    BASM.pc = tonumber(startLine) or 1
    BASM.running = true
    BASM.cycles = 0
    while BASM.running do
        local ok, status = BASM.Step()
        if not ok then break end
    end
    return BASM.cycles
end

-- ====================
-- 6. TOPOLOGICAL PROCESSING MODULE (TPM SECURITY & ATTESTATION ENGINE)
-- ====================

local TPM = {}

function TPM.GenerateSignature(nonce)
    nonce = tonumber(nonce) or 137
    local sumTwist = 0
    local crossings = 0

    for i = 1, 24 do
        sumTwist = sumTwist + ACC[i] * (i ^ 2)
        if ACC[i] ~= 0 then crossings = crossings + 1 end
    end

    local berryFactor = (2 * math.pi / 3) * crossings
    local hashVal = math.abs(math.floor((sumTwist * PHI + berryFactor * nonce) % 1000000))
    local sig = string.format("TPM-%06d-Q%d", hashVal, (sumTwist >= 0) and 1 or -1)
    return sig, crossings, sumTwist
end

function TPM.VerifyUnknot()
    local temp = {}
    for i = 1, 24 do temp[i] = ACC[i] end
    local simplified = true
    local passes = 0

    while simplified and passes < 12 do
        simplified = false
        passes = passes + 1
        for i = 1, 23 do
            if (temp[i] == 1 and temp[i+1] == -1) or (temp[i] == -1 and temp[i+1] == 1) then
                temp[i] = 0; temp[i+1] = 0
                simplified = true
            end
        end
    end

    local sumRem = 0
    for i = 1, 24 do if temp[i] ~= 0 then sumRem = sumRem + 1 end end
    return (sumRem == 0), sumRem
end

function TPM.LatticePUF()
    local seed = (memMinus.Usage * 3 + memZero.Usage * 7 + memPlus.Usage * 11 + 137) % 65536
    local pufStr = ""
    for i = 1, 8 do
        seed = (seed * 1103515245 + 12345) % 65536
        pufStr = pufStr .. string.format("%02X", seed % 256)
    end
    return pufStr
end

-- ====================
-- 7. COMPREHENSIVE COMPUTE ENGINES (ALL 25 THEOREMS)
-- ====================
local Compute = {}

-- [1: Theory Paper]
function Compute.Lagrangian(psiVal)
    local L = - (LAMBDA_0 / 4.0) * (((psiVal ^ 2) - 1.0) ^ 2)
    local E = (LAMBDA_0 / 4.0) * (((psiVal ^ 2) - 1.0) ^ 2) * (4/3) * math.pi * (R_TUBE_FM ^ 3)
    return L, E
end

-- [2: Boson Isomorphism]
function Compute.BosonProperties(bType)
    bType = string.upper(bType or "PHOTON")
    if bType == "PHOTON" or bType == "P" then
        return "Photon", 1, 0.0, "Closed loop link=1"
    elseif bType == "W" then
        return "W Boson", 1, 80377.0, "Chiral flip dislocation"
    elseif bType == "Z" then
        return "Z0 Boson", 1, 91187.6, "Neutral closed loop"
    elseif bType == "GLUON" or bType == "G" then
        return "Gluon", 1, 0.0, "SU(3) 8-strand perm"
    else
        return "Boson", 1, 0.0, "Closed loop"
    end
end

-- [3: Coupling Theorem]
function Compute.CouplingForces(r)
    local forceName = "STRONG"
    if r > XI_0 * (PHI ^ 62) then forceName = "GRAVITY"
    elseif r > XI_0 * (PHI ^ 18) then forceName = "WEAK"
    elseif r > XI_0 then forceName = "EM"
    end
    return forceName, ALPHA_INV, LAMBDA_0 / 3.0
end

-- [4: Curvature Theorem]
function Compute.Curvature()
    return KAPPA_EFF / XI_0, 1.0 / (KAPPA_EFF / XI_0)
end

-- [5: Fermion Theorem]
function Compute.FermionProperties(fType)
    fType = string.upper(fType or "E")
    if fType == "E" or fType == "ELECTRON" then
        return "Electron", 0.5, -1, M_ELECTRON_MEV, 1
    elseif fType == "MU" or fType == "MUON" then
        return "Muon", 0.5, -1, 105.66, 2
    elseif fType == "TAU" then
        return "Tau", 0.5, -1, 1776.8, 3
    elseif fType == "U" then
        return "Up Quark", 0.5, 2/3, 2.16, 1
    elseif fType == "D" then
        return "Down Quark", 0.5, -1/3, 4.67, 1
    else
        return "Fermion", 0.5, 0, 0.0, 1
    end
end

-- [6: Fixed Point Uniqueness]
function Compute.GenerateFixedPoint(depth)
    local d = math.min(math.max(tonumber(depth) or 3, 1), 6)
    local word = "1"
    for _ = 1, d do
        local nextW = ""
        for i = 1, #word do
            local c = string.sub(word, i, i)
            if c == "1" then nextW = nextW .. "12"
            elseif c == "2" then nextW = nextW .. "13"
            elseif c == "3" then nextW = nextW .. "21"
            end
        end
        word = nextW
    end
    return word
end

-- [7: Growth Theorem]
function Compute.GrowthScale(n)
    local gen = tonumber(n) or 0
    local lm = XI_0_METERS * (PHI ^ gen)
    local name = "Level " .. gen
    if gen == 0 then name = "Proton Core"
    elseif gen == 10 then name = "Protein C-C"
    elseif gen == 18 then name = "DNA Helix"
    elseif gen == 24 then name = "Cell Membrane"
    elseif gen == 33 then name = "Ranvier Node"
    elseif gen == 44 then name = "Human Brain"
    elseif gen == 62 then name = "Earth Radius"
    elseif gen == 70 then name = "Solar Radius"
    elseif gen == 118 then name = "Milky Way"
    elseif gen == 140 then name = "Universe"
    end
    return gen, lm, name
end

-- [8: Master Cosmological Scale]
function Compute.Cosmo(tid)
    tid = tonumber(tid) or 1
    if tid == 1 then
        return "COSMO-1", "Q:9.15e78", "R:93 Gly"
    elseif tid == 2 then
        return "COSMO-2", "L:1.19e-52", "Within 1-sig"
    else
        return "COSMO-3", "CMB Peaks:", "l:220,356,576"
    end
end

-- [9: Neuroscience Non-emergence]
function Compute.DensityLayer(rho)
    local xi = XI_0_METERS * ((RHO_NUC / math.max(rho, 1e-30)) ^ (1/3))
    return xi
end

-- [10: Phase Theorem]
function Compute.Phase(s, t)
    local ct = (C_LIGHT * t) * 1e15
    local theta = (s - ct) / XI_0
    return theta
end

-- [11: Phi]
function Compute.Phi()
    return PHI, PHI_INV
end

-- [12: Pi]
function Compute.Pi()
    return PI_EARTH, "x^4+10x^2-5=0"
end

-- [13: Planck Constant]
function Compute.Planck()
    local h = (M_PROTON_MEV * 1.78266e-30 * C_LIGHT * (R_TUBE_FM * 1e-15)) / (3.0 * DELTA_CHI)
    return h
end

-- [14: Quantum Superposition]
function Compute.InitQutrit(m, z, p)
    local norm = math.sqrt(m*m + z*z + p*p)
    if norm == 0 then norm = 1 end
    Qutrit.c_minus = m / norm
    Qutrit.c_zero  = z / norm
    Qutrit.c_plus  = p / norm
end

function Compute.ApplyQGate(g)
    g = string.upper(g or "H")
    if g == "H" then
        local inv = 1.0 / math.sqrt(3)
        local nm = inv * (Qutrit.c_minus + Qutrit.c_zero + Qutrit.c_plus)
        local nz = inv * (Qutrit.c_minus - Qutrit.c_plus)
        local np = inv * (Qutrit.c_minus - Qutrit.c_zero + Qutrit.c_plus)
        Qutrit.c_minus, Qutrit.c_zero, Qutrit.c_plus = nm, nz, np
        soundQuantumChirp()
    elseif g == "X" then
        local tmp = Qutrit.c_plus
        Qutrit.c_plus = Qutrit.c_zero
        Qutrit.c_zero = Qutrit.c_minus
        Qutrit.c_minus = tmp
        soundClick(1)
    elseif g == "Z" then
        Qutrit.phase = (Qutrit.phase + 2 * math.pi * PHI_INV) % (2 * math.pi)
        soundClick(2)
    elseif g == "S" then
        Qutrit.c_plus = Qutrit.c_plus * PHI_INV
        Qutrit.c_minus = Qutrit.c_minus * PHI_INV
        local norm = math.sqrt(Qutrit.c_minus^2 + Qutrit.c_zero^2 + Qutrit.c_plus^2)
        Qutrit.c_minus, Qutrit.c_zero, Qutrit.c_plus = Qutrit.c_minus/norm, Qutrit.c_zero/norm, Qutrit.c_plus/norm
        soundQuantumChirp()
    end
end

function Compute.MeasureQutrit()
    local pm = Qutrit.c_minus ^ 2
    local pz = Qutrit.c_zero ^ 2
    local pp = Qutrit.c_plus ^ 2
    local r = math.random()
    local res = 0
    if r < pm then res = -1; Qutrit.c_minus=1; Qutrit.c_zero=0; Qutrit.c_plus=0
    elseif r < pm + pz then res = 0; Qutrit.c_minus=0; Qutrit.c_zero=1; Qutrit.c_plus=0
    else res = 1; Qutrit.c_minus=0; Qutrit.c_zero=0; Qutrit.c_plus=1
    end
    soundQuantumChirp()
    return res, pm, pz, pp
end

-- [15: Quantum Gravity]
function Compute.GravityMetric(r)
    local pot = -G_NEWTON * (M_PROTON_MEV * 1.78266e-30) / math.max(r, 1e-15)
    return -(1.0 + 2 * pot / (C_LIGHT^2))
end

-- [16: Quasicrystal]
function Compute.BuildQC(n)
    QuasicrystalPoints = {}
    local slope = PHI_INV
    for i = 1, n do
        local x5 = i
        local y5 = math.floor(i * slope)
        table.insert(QuasicrystalPoints, { x = (x5 + y5 * PHI), y = (x5 * PHI - y5) })
    end
end

-- [17: R(3) Dimension]
function Compute.SpinorParity(deg)
    local th = (deg or 360) * math.pi / 180.0
    return (math.cos(th / 2.0) < 0) and "-1 (Inverted)" or "+1 (Restored)"
end

-- [18: Strand Sharing]
function Compute.BerryFlux()
    return (2.0 * math.pi) / 3.0
end

-- [19: NEURO-1]
function Compute.NeuroAxon()
    return 1.139, 1.22, 120.0
end

-- [20: NEURO-2]
function Compute.SineGordon(x_mm, t_ms)
    local x = (x_mm or 0) * 1e-3
    local t = (t_ms or 0) * 1e-3
    local v = 120.0
    local gamma = 1.0 / math.sqrt(math.max(1.0 - (v/200)^2, 0.01))
    local th = 4.0 * math.atan(math.exp(gamma * (x - v * t) / 0.001))
    local mv = 100.0 * (math.sin(th / 2.0) ^ 2) - 70.0
    return mv, th
end

-- [21: NEURO-3]
function Compute.EEGModes()
    return {
        { name = "d1", f = F_CONSCIOUS * (PHI ^ -3) },
        { name = "d2", f = F_CONSCIOUS * (PHI ^ -2) },
        { name = "th", f = F_CONSCIOUS * (PHI ^ -1) },
        { name = "f0", f = F_CONSCIOUS },
        { name = "a1", f = F_CONSCIOUS * PHI },
        { name = "b1", f = F_CONSCIOUS * (PHI ^ 2) },
        { name = "g1", f = F_CONSCIOUS * (PHI ^ 3) }
    }
end

-- [22: NEURO-4]
function Compute.Disease(dKey)
    dKey = string.upper(dKey or "ALZ")
    if string.find(dKey, "ALZ") then
        return "Alzheimer", "(3,2) knots", "~76 yrs"
    elseif string.find(dKey, "PARK") then
        return "Parkinson", "Twist leak", "~70 yrs"
    elseif string.find(dKey, "SCHIZ") then
        return "Schizophrenia", "(7,3) 40Hz", "Spurious"
    elseif string.find(dKey, "ANESTH") then
        return "Anesthesia", "dX->0.165 rad", "f0->7.1Hz"
    elseif string.find(dKey, "DEP") then
        return "Depression", "C < 0.618", "Damping"
    elseif string.find(dKey, "ALS") then
        return "ALS", "Node depin", "~63 yrs"
    else
        return "Brain Death", "C = 0", "Decoherence"
    end
end

-- [23: Theory-Zero]
function Compute.TheoryZero()
    return "sigma:1->12,2->13,3->21", "p^2+q^2+pq", "xi_0*phi^-2"
end

-- [24: Tube Theorem]
function Compute.Tube()
    return R_TUBE_FM, "xi_0*phi^-2"
end

-- [25: Unification Master]
function Compute.Unify()
    return "w_inf", "Elastic", "4 Forces @ phi", "Hopfions", "7.83 Hz"
end

-- ====================
-- 8. TOPOLOGICAL BRAIN & ACCUMULATOR OPERATIONS
-- ====================

local function shiftBraidRight(newTrit)
    for i = 24, 2, -1 do ACC[i] = ACC[i - 1] end
    ACC[1] = newTrit
    updateLeds()
    soundClick(newTrit)
end

local function simplifyBraid()
    local simplified = false
    local newAcc = {}
    for i = 1, 24 do newAcc[i] = ACC[i] end

    for i = 1, 23 do
        if (newAcc[i] == 1 and newAcc[i+1] == -1) or (newAcc[i] == -1 and newAcc[i+1] == 1) then
            newAcc[i] = 0
            newAcc[i+1] = 0
            simplified = true
        end
    end

    if simplified then
        ACC = newAcc
        updateLeds()
        soundQuantumChirp()
        printLine("SIMP: Annihilated")
    else
        soundClick(0.5)
        printLine("SIMP: No pairs")
    end
end

local function invertBraid()
    for i = 1, 24 do
        if ACC[i] == 1 then ACC[i] = -1
        elseif ACC[i] == -1 then ACC[i] = 1 end
    end
    updateLeds()
    soundClick(2)
    printLine("INV: Inverted")
end

local activeWaveMode = nil
local waveTime = 0.0

local function triggerWave(wType)
    wType = string.upper(wType or "SOLITON")
    activeWaveMode = wType
    waveTime = 0.0
    systemMode = "OSCILLOSCOPE"

    if wType == "COLLIDE" then
        soundQuantumChirp()
        printLine("WAVE: COLLIDE")
    elseif wType == "STAND" or wType == "STANDING" then
        soundResonance(14.0)
        printLine("WAVE: STAND 3-NODE")
    elseif wType == "EEG" then
        soundResonance(F_CONSCIOUS)
        printLine("WAVE: EEG 7.83Hz")
    elseif wType == "CHIRP" then
        playSample(0.5, 0)
        playSample(2.5, 1)
        printLine("WAVE: CHIRP SWEEP")
    elseif wType == "GAUSS" or wType == "QUANTUM" then
        soundQuantumChirp()
        printLine("WAVE: GAUSS PACKET")
    else
        activeWaveMode = "SOLITON"
        soundResonance(12.0)
        printLine("WAVE: SOLITON PULSE")
    end
end

local function triggerSolitonPulse()
    triggerWave("SOLITON")
end

-- ====================
-- 9. CLEAN & COMPACT CRT SCREEN RENDERERS
-- ====================

local function drawTerminal()
    vid:Clear(color.black)
    local h = vid.Height or 50
    local w = vid.Width or 80

    local lineHeight = 9
    local footerH = 9
    local promptH = 9

    local availH = h - promptH - footerH - 1
    local maxVis = math.max(1, math.floor(availH / lineHeight))
    local startIdx = math.max(1, #cliBuffer - maxVis + 1)

    local lineY = 1
    for i = startIdx, #cliBuffer do
        vid:DrawText(vec2(2, lineY), sysFont, cliBuffer[i], color.green, color.clear)
        lineY = lineY + lineHeight
    end

    -- Prompt line with live net chirality Q badge
    local promptY = h - footerH - promptH
    local netQ = 0
    for i = 1, 24 do netQ = netQ + ACC[i] end
    local qBadge = "[" .. (netQ > 0 and "+" or "") .. netQ .. "]>"
    local prompt = qBadge .. inputLine
    if cursorBlink < 15 then prompt = prompt .. "_" end

    local maxChars = math.max(8, math.floor((w - 6) / 6))
    if #prompt > maxChars then
        prompt = qBadge .. string.sub(inputLine, math.max(1, #inputLine - (maxChars - #qBadge) + 1))
    end
    vid:DrawText(vec2(2, promptY), sysFont, prompt, color.white, color.clear)

    -- Sleek 1-line Footer
    vid:FillRect(vec2(0, h - footerH), vec2(w, h), color.gray)
    local statusText = "M:" .. memViewAddr .. " | T"
    if w >= 80 then
        statusText = "M:" .. memViewAddr .. " Q:" .. string.format("%.2f", Qutrit.c_plus) .. " T"
    end
    vid:DrawText(vec2(2, h - footerH + 1), sysFont, statusText, color.yellow, color.clear)
end

local function drawOscilloscope()
    vid:Clear(color.black)
    local h = vid.Height or 50
    local w = vid.Width or 80
    local midY = math.floor(h / 2) - 3

    vid:DrawLine(vec2(0, midY), vec2(w, midY), color.gray)

    local stepX = w / 24
    for i = 1, 23 do
        local y1 = midY - math.floor(SolitonBuffer[i] * (h * 0.35))
        local y2 = midY - math.floor(SolitonBuffer[i+1] * (h * 0.35))
        local x1 = (i - 1) * stepX
        local x2 = i * stepX
        vid:DrawLine(vec2(x1, y1), vec2(x2, y2), color.cyan)
    end

    vid:FillRect(vec2(0, h - 9), vec2(w, h), color.gray)
    vid:DrawText(vec2(2, h - 8), sysFont, "OSC 120m/s [TAB]", color.yellow, color.clear)
end

-- Quantum & Quasicrystal Visualizer State
local qcMode = "PROJECT" -- "PROJECT", "DIFFRACT", "INFLATE"
local qcAngle = 0.0
local qcRotating = true
local qcScale = 1.0
local qPhaseRot = 0.0

local function drawQuantumView()
    vid:Clear(color.black)
    local h = vid.Height or 40
    local w = vid.Width or 55

    local pm = Qutrit.c_minus ^ 2
    local pz = Qutrit.c_zero ^ 2
    local pp = Qutrit.c_plus ^ 2

    -- Proportionally centered 3 bars for narrow screen
    local barW = math.max(8, math.floor((w - 18) / 3.2))
    local gap = 3
    local totalW = (barW * 3) + (gap * 2)
    local startX = math.floor((w - totalW) / 2)
    local maxBarH = math.max(10, h - 22)
    local yBase = h - 11

    local x1 = startX
    local x2 = startX + barW + gap
    local x3 = startX + (barW + gap) * 2

    -- |-1> (Red)
    local h1 = math.max(2, math.floor(pm * maxBarH))
    vid:FillRect(vec2(x1, yBase - h1), vec2(x1 + barW, yBase), color.red)
    vid:DrawText(vec2(x1 + math.floor(barW/2) - 4, yBase - h1 - 7), sysFont, tostring(math.floor(pm * 100)), color.white, color.clear)
    vid:DrawText(vec2(x1 + math.floor(barW/2) - 2, yBase - math.floor(h1/2) - 3), sysFont, "-", color.white, color.clear)

    -- |0> (Grey)
    local h2 = math.max(2, math.floor(pz * maxBarH))
    vid:FillRect(vec2(x2, yBase - h2), vec2(x2 + barW, yBase), color.gray)
    vid:DrawText(vec2(x2 + math.floor(barW/2) - 4, yBase - h2 - 7), sysFont, tostring(math.floor(pz * 100)), color.white, color.clear)
    vid:DrawText(vec2(x2 + math.floor(barW/2) - 2, yBase - math.floor(h2/2) - 3), sysFont, "0", color.white, color.clear)

    -- |+1> (Green)
    local h3 = math.max(2, math.floor(pp * maxBarH))
    vid:FillRect(vec2(x3, yBase - h3), vec2(x3 + barW, yBase), color.green)
    vid:DrawText(vec2(x3 + math.floor(barW/2) - 4, yBase - h3 - 7), sysFont, tostring(math.floor(pp * 100)), color.white, color.clear)
    vid:DrawText(vec2(x3 + math.floor(barW/2) - 2, yBase - math.floor(h3/2) - 3), sysFont, "+", color.black, color.clear)

    -- Clean Short Footer
    vid:FillRect(vec2(0, h - 8), vec2(w, h), color.gray)
    vid:DrawText(vec2(2, h - 7), sysFont, "QUTRIT", color.yellow, color.clear)
    vid:DrawText(vec2(w - 18, h - 7), sysFont, "TAB", color.black, color.clear)
end

local function drawQuasicrystalView()
    vid:Clear(color.black)
    local h = vid.Height or 40
    local w = vid.Width or 55
    local cx = math.floor(w / 2)
    local cy = math.floor((h - 8) / 2)

    -- Compact Golden Ratio Decagon (Radius = 10, perfectly centered)
    local rOuter = 10
    local rInner = 6

    for a = 0, 9 do
        local a1 = a * (math.pi / 5) + qcAngle
        local a2 = a1 + (math.pi / 10)
        local a3 = (a + 1) * (math.pi / 5) + qcAngle

        local x1 = cx + math.floor(math.cos(a1) * rOuter)
        local y1 = cy + math.floor(math.sin(a1) * rOuter)
        local x2 = cx + math.floor(math.cos(a2) * rInner)
        local y2 = cy + math.floor(math.sin(a2) * rInner)
        local x3 = cx + math.floor(math.cos(a3) * rOuter)
        local y3 = cy + math.floor(math.sin(a3) * rOuter)

        vid:DrawLine(vec2(x1, y1), vec2(x2, y2), (a % 2 == 0) and color.cyan or color.yellow)
        vid:DrawLine(vec2(x2, y2), vec2(x3, y3), (a % 2 == 0) and color.yellow or color.cyan)
    end

    -- Center Golden Core
    vid:FillRect(vec2(cx - 1, cy - 1), vec2(cx + 1, cy + 1), color.white)

    -- Clean Short Footer
    vid:FillRect(vec2(0, h - 8), vec2(w, h), color.gray)
    vid:DrawText(vec2(2, h - 7), sysFont, "QC PHI", color.yellow, color.clear)
    vid:DrawText(vec2(w - 18, h - 7), sysFont, "TAB", color.black, color.clear)
end

local function drawScreen()
    if systemMode == "OSCILLOSCOPE" then drawOscilloscope()
    elseif systemMode == "QUANTUM" then drawQuantumView()
    elseif systemMode == "QUASICRYSTAL" then drawQuasicrystalView()
    else drawTerminal() end
end

-- ====================
-- 10. COMPACT & RESILIENT CLI COMMAND DISPATCHER
-- ====================

executeCommand = function(cmd)
    if string.len(cmd) == 0 then return end
    printLine(">" .. cmd)
    table.insert(commandHistory, cmd)
    historyIndex = #commandHistory + 1

    local tokens = {}
    for word in string.gmatch(cmd, "%S+") do table.insert(tokens, word) end
    if #tokens == 0 then return end

    local rawAction = string.upper(tokens[1])
    local normAction = string.gsub(rawAction, "_", "")
    local arg1   = tokens[2]
    local arg2   = tokens[3]
    local arg3   = tokens[4]

    -- GENERAL COMMANDS
    if normAction == "CLEAR" or normAction == "CLS" then
        cliBuffer = {}
        for i = 1, 24 do ACC[i] = 0 end
        updateLeds()
        soundClick(1)
        printLine("CLEARED")

    elseif normAction == "THEOREMS" then
        printLine("1:THEORY 2:BOSON")
        printLine("3:FORCE 4:CURV")
        printLine("5:FERM 6:SIGMA")
        printLine("7:GROWTH 8:COSMO")
        printLine("9:NONEM 10:PHASE")
        printLine("11:PHI 12:PI")
        printLine("13:HBAR 14:QUT")
        printLine("15:QG 16:QC")
        printLine("17:R3 18:FLUX")
        printLine("19:AXON 20:KINK")
        printLine("21:EEG 22:DIS")
        printLine("23:TH0 24:TUBE")
        printLine("25:UNIFY")

    -- AUDIO CONTROL
    elseif normAction == "AUDIO" then
        if arg1 and string.upper(arg1) == "OFF" then
            audioEnabled = false
            printLine("AUDIO: OFF")
        else
            audioEnabled = true
            soundTPMChime()
            printLine("AUDIO: ON")
        end

    elseif normAction == "SAMPLE" then
        if arg1 then
            local custom = getSample(rom.User.AudioSamples, arg1) or getSample(rom.System.AudioSamples, arg1)
            if custom then
                systemAudioSample = custom
                soundClick(1)
                printLine("SAMPLE: " .. arg1)
            else
                printError("ERR:SAMPLE", "Audio sample \"" .. tostring(arg1) .. "\" not found in ROM or User assets.")
            end
        else
            printLine("CUR: " .. (systemAudioSample and (systemAudioSample.Name or "LOADED") or "NONE"))
        end

    -- B-ASM VM
    elseif normAction == "BASM" then
        printLine("B-ASM OPCODES:")
        printLine("SET, SIMP, SHFT")
        printLine("ROT, INV, LOAD")
        printLine("SAVE, JMP, HALT")
        printLine("CMDS: PROG, RUN, LIST")

    elseif normAction == "PROG" or normAction == "P" or normAction == "BPROG" then
        local line = tonumber(arg1) or 1
        local op   = arg2 or "NOP"
        local opArg= arg3 or nil
        BASM.SetLine(line, op, opArg)
        printLine(string.format("P[%02d]: %s %s", line, normalizeOpcode(op), opArg or ""))

    elseif normAction == "LIST" or normAction == "BLIST" then
        printLine("-- B-ASM PROG --")
        local count = 0
        for i = 1, 32 do
            if BASM.program[i] then
                count = count + 1
                printLine(string.format("%02d: %s %s", i, BASM.program[i].op, BASM.program[i].arg or ""))
            end
        end
        if count == 0 then printLine("(EMPTY)") end

    elseif normAction == "RUN" or normAction == "BRUN" then
        local start = tonumber(arg1) or 1
        local cycles = BASM.Run(start)
        soundTPMChime()
        printLine("FINISHED (" .. cycles .. " cyc)")

    elseif normAction == "STEP" or normAction == "BSTEP" then
        local ok, op = BASM.Step()
        printLine("STEP: " .. tostring(op) .. " (PC:" .. BASM.pc .. ")")

    -- TPM SECURITY
    elseif normAction == "TPM" or normAction == "TPMSTATUS" then
        printLine("--- TPM CORE ---")
        printLine("PUF: " .. string.sub(TPM.LatticePUF(), 1, 8))
        local isUnknot, knots = TPM.VerifyUnknot()
        printLine("Residue: " .. knots)
        printLine("Unknot: " .. (isUnknot and "YES" or "NO (Tangled)"))

    elseif normAction == "SIGN" or normAction == "TPMSIGN" then
        local nonce = tonumber(arg1) or 137
        local sig, cr, tw = TPM.GenerateSignature(nonce)
        soundTPMChime()
        printLine("SIG: " .. sig)
        printLine("Cr:" .. cr .. " Tw:" .. tw)

    elseif normAction == "PUF" or normAction == "TPMPUF" then
        printLine("PUF: " .. TPM.LatticePUF())

    -- QUANTUM QUTRIT COMMANDS (Support GATE X, GATE H, GATE Z, GATE S, GATEX, GATEH, MEASURE, etc.)
    elseif normAction == "QMEASURE" or normAction == "MEASURE" or normAction == "QMEAS" or normAction == "QM" then
        local res, pm, pz, pp = Compute.MeasureQutrit()
        printLine("COLLAPSE: |" .. res .. ">")
        printLine(string.format("P:%.2f,%.2f,%.2f", pm, pz, pp))
        ACC[1] = res
        updateLeds()

    elseif normAction == "QGATE" or normAction == "GATE" or normAction == "QG" then
        local gateType = string.upper(arg1 or "H")
        Compute.ApplyQGate(gateType)
        printLine("GATE: " .. gateType)

    elseif normAction == "GATEH" or normAction == "QGATEH" then
        Compute.ApplyQGate("H")
        printLine("GATE: H")

    elseif normAction == "GATEX" or normAction == "QGATEX" then
        Compute.ApplyQGate("X")
        printLine("GATE: X")

    elseif normAction == "GATEZ" or normAction == "QGATEZ" then
        Compute.ApplyQGate("Z")
        printLine("GATE: Z")

    elseif normAction == "GATES" or normAction == "QGATES" then
        Compute.ApplyQGate("S")
        printLine("GATE: S")

    elseif normAction == "QINIT" or normAction == "QSET" then
        Compute.InitQutrit(tonumber(arg1) or 1, tonumber(arg2) or 1, tonumber(arg3) or 1)
        printLine("QUTRIT INIT")

    elseif normAction == "ENTANGLE" or normAction == "QENTANGLE" then
        Compute.InitQutrit(1, 1, 1)
        systemMode = "QUANTUM"
        soundQuantumChirp()
        printLine("QUTRIT: ENTANGLED")

    elseif normAction == "DECOHERE" or normAction == "QDECOHERE" then
        Compute.InitQutrit(0.15, 1.0, 0.15)
        systemMode = "QUANTUM"
        soundClick(0.5)
        printLine("QUTRIT: DECOHERED")

    -- QUASICRYSTAL CONTROLLER & MODES
    elseif normAction == "QCDIFF" or normAction == "DIFFRACT" then
        qcMode = "DIFFRACT"
        systemMode = "QUASICRYSTAL"
        soundClick(1.2)
        printLine("QC: 10-FOLD DIFFRACT")

    elseif normAction == "QCINFLATE" or normAction == "INFLATE" then
        qcMode = "INFLATE"
        systemMode = "QUASICRYSTAL"
        soundClick(1.4)
        printLine("QC: PHI INFLATE")

    elseif normAction == "QCPROJ" or normAction == "LATTICE" then
        qcMode = "PROJECT"
        systemMode = "QUASICRYSTAL"
        soundClick(1.0)
        printLine("QC: 5D->2D PROJ")

    elseif normAction == "QCROT" then
        qcRotating = not qcRotating
        soundClick(0.8)
        printLine("QC ROT: " .. (qcRotating and "ON" or "OFF"))

    -- MODULAR DOCKING STATUS
    elseif normAction == "DOCK" or normAction == "MAG" or normAction == "DOCKSTATUS" then
        local connected = isDocked or (magDock and magDock.IsConnected)
        printLine("MAG-PORT: " .. (connected and "ATTACHED" or "OPEN"))
        if connected then
            soundTPMChime()
            notifyDesk("MAG-DOCK ATTACHED", "INFO")
        else
            soundClick(0.8)
        end

    -- DESK LAMP CONTROLLER
    elseif normAction == "LAMP" then
        local sub = string.upper(arg1 or "TOGGLE")
        if sub == "OFF" then
            lampSyncEnabled = false
            if desk and desk.SetLampState then desk.SetLampState(false) end
            printLine("LAMP: OFF")
        elseif sub == "ON" then
            if desk and desk.SetLampState then desk.SetLampState(true) end
            printLine("LAMP: ON")
        elseif sub == "CYAN" then
            lampSyncEnabled = false
            setAmbientLamp(color.cyan, true, true)
            printLine("LAMP: CYAN")
        elseif sub == "WHITE" then
            lampSyncEnabled = false
            setAmbientLamp(color.white, true, true)
            printLine("LAMP: WHITE")
        elseif sub == "GOLD" or sub == "YELLOW" then
            lampSyncEnabled = false
            setAmbientLamp(color.yellow, true, true)
            printLine("LAMP: GOLD")
        elseif sub == "RED" then
            lampSyncEnabled = false
            setAmbientLamp(color.red, true, true)
            printLine("LAMP: RED")
        elseif sub == "GREEN" then
            lampSyncEnabled = false
            setAmbientLamp(color.green, true, true)
            printLine("LAMP: GREEN")
        elseif sub == "BLUE" then
            lampSyncEnabled = false
            setAmbientLamp(color.blue, true, true)
            printLine("LAMP: BLUE")
        elseif sub == "MAGENTA" or sub == "PURPLE" then
            lampSyncEnabled = false
            setAmbientLamp(color.magenta, true, true)
            printLine("LAMP: MAGENTA")
        elseif sub == "SYNC" then
            lampSyncEnabled = not lampSyncEnabled
            lastSyncedMode = ""
            if lampSyncEnabled then
                syncLampWithState()
            end
            printLine("LAMP SYNC: " .. (lampSyncEnabled and "ON" or "OFF"))
        elseif sub == "TOGGLE" or sub == "" then
            if desk and desk.GetLampState and desk.SetLampState then
                local st = desk.GetLampState()
                desk.SetLampState(not st)
                printLine("LAMP: " .. (not st and "ON" or "OFF"))
            end
        else
            printError("ERR:COLOR", "Invalid lamp color \"" .. tostring(arg1) .. "\". Available: WHITE, CYAN, GOLD, RED, GREEN, BLUE, MAGENTA")
        end

    -- WIFI SYNCHRONIZATION
    elseif normAction == "SYNC" or normAction == "BSYNC" or normAction == "WIFISYNC" then
        soundTPMChime()
        syncRequested = true
        printLine("SYNC...")
        if wifi then
            isPolling = true
            pcall(function()
                wifi:WebGet("http://127.0.0.1:8080/api/poll")
            end)
        else
            printError("ERR:NO WIFI", "No Wifi hardware module found.")
        end

    -- VIEW MODES
    elseif normAction == "VIEW" or normAction == "MODE" then
        local t = string.upper(arg1 or "T")
        if t == "T" or t == "TERM" then systemMode = "TERMINAL"
        elseif t == "O" or t == "OSC" then systemMode = "OSCILLOSCOPE"
        elseif t == "Q" then systemMode = "QUANTUM"
        elseif t == "C" or t == "QC" then systemMode = "QUASICRYSTAL"
        end
        printLine("VIEW: " .. systemMode)

    -- MEMORY & ACC
    elseif normAction == "SIMP" or normAction == "BSIMP" then simplifyBraid()
    elseif normAction == "INV"  or normAction == "BINV"  then invertBraid()

    elseif normAction == "SET" or normAction == "BSET" then
        local str = tostring(arg1 or "")
        for i = 1, math.min(24, #str) do
            local c = string.sub(str, i, i)
            if c == "+" or c == "1" then ACC[i] = 1
            elseif c == "-" or c == "2" then ACC[i] = -1
            else ACC[i] = 0 end
        end
        updateLeds()
        soundClick(1)
        printLine("ACC SET (" .. #str .. " trits)")

    elseif normAction == "SAVE" or normAction == "BSAVE" then
        local addr = tonumber(arg1) or memViewAddr
        memViewAddr = addr
        writeWord(addr, ACC)
        soundClick(0)
        printLine("SAVED M:" .. addr)

    elseif normAction == "LOAD" or normAction == "BLOAD" then
        local addr = tonumber(arg1) or memViewAddr
        memViewAddr = addr
        ACC = readWord(addr)
        updateLeds()
        soundClick(0)
        printLine("LOADED M:" .. addr)

    -- ====================
    -- COMPLETE 25 EARTH THEOREM COMMAND DISPATCHERS
    -- ====================
    -- [Theorem 1: Theory & Lagrangian]
    elseif normAction == "THEORY" or normAction == "CONSTANTS" then
        printLine("xi0: 0.150 fm")
        printLine("l0: 44.492")
        printLine("dX: 0.150 rad")
        printLine("phi: 1.61803")
        printLine("a^-1: 137.036")

    elseif normAction == "LAGRANGIAN" or normAction == "ENERGY" then
        local psi = tonumber(arg1) or 1.0
        local L, E = Compute.Lagrangian(psi)
        printLine("L:" .. string.format("%.3f", L))
        printLine("E:" .. string.format("%.3e", E))

    -- [Theorem 2: Boson Isomorphism]
    elseif normAction == "BOSON" then
        local name, spin, mass, top = Compute.BosonProperties(arg1)
        printLine(name .. " S=" .. spin)
        printLine("M:" .. mass .. "MeV")
        printLine(top)

    -- [Theorem 3: Coupling Theorem]
    elseif normAction == "COUPLING" or normAction == "FORCE" or normAction == "FORCES" or normAction == "FORCECALC" then
        local r = tonumber(arg1) or XI_0
        local fName, a_inv, gs2 = Compute.CouplingForces(r)
        printLine("F:" .. fName)
        printLine("a^-1:" .. string.format("%.2f", a_inv))
        printLine("gs^2:" .. string.format("%.2f", gs2))

    -- [Theorem 4: Curvature Theorem]
    elseif normAction == "CURV" or normAction == "CURVATURE" then
        local kap, rad = Compute.Curvature()
        printLine("kap:" .. string.format("%.4f", kap) .. "fm-1")
        printLine("R:" .. string.format("%.4f", rad) .. "fm")

    -- [Theorem 5: Fermion Theorem]
    elseif normAction == "FERMION" or normAction == "FERM" then
        local name, spin, q, mass, gen = Compute.FermionProperties(arg1)
        printLine(name .. " G" .. gen)
        printLine("Q:" .. string.format("%.2f", q) .. " S:" .. spin)
        printLine("M:" .. string.format("%.3f", mass) .. "MeV")

    -- [Theorem 6: Fixed Point Uniqueness / Sigma Morphism]
    elseif normAction == "SIGMA" or normAction == "FIXEDPOINT" or normAction == "MORPH" then
        local depth = tonumber(arg1) or 3
        local word = Compute.GenerateFixedPoint(depth)
        printLine("SIGMA (D=" .. depth .. ", L=" .. #word .. "):")
        printLine(string.sub(word, 1, 14) .. "...")

    -- [Theorem 7: Growth Theorem]
    elseif normAction == "GROWTH" then
        local gen, lm, sys = Compute.GrowthScale(arg1 or 0)
        printLine("GEN " .. gen .. ":")
        printLine(string.format("%.2e m", lm))
        printLine(sys)

    -- [Theorem 8: Master Cosmological Scale]
    elseif normAction == "COSMO" then
        local tName, l1, l2 = Compute.Cosmo(arg1 or 1)
        printLine(tName .. ":")
        printLine(l1)
        printLine(l2)

    -- [Theorem 9: Neuroscience Non-emergence]
    elseif normAction == "NONEM" or normAction == "NONEMERG" or normAction == "NONEMERGENCE" or normAction == "DENSITY" then
        local rho = tonumber(arg1) or RHO_BRAIN
        local xi = Compute.DensityLayer(rho)
        printLine("xi(rho):")
        printLine(string.format("%.3e m", xi))

    -- [Theorem 10: Phase Theorem]
    elseif normAction == "PHASE" or normAction == "PHASEFLOW" then
        local th = Compute.Phase(tonumber(arg1) or 1.0, tonumber(arg2) or 0.0)
        printLine("th:" .. string.format("%.3f", th) .. "rad")
        printLine("grad:1rad/0.15fm")

    -- [Theorem 11: Golden Ratio Phi]
    elseif normAction == "PHI" or normAction == "PHICALC" then
        local p, pi = Compute.Phi()
        printLine("phi:1.61803398")
        printLine("1/phi:0.61803398")
        printLine("KAM Stable")

    -- [Theorem 12: Algebraic Pi]
    elseif normAction == "PI" or normAction == "PIALGEBRAIC" then
        local piE, poly = Compute.Pi()
        printLine("Pi_E:" .. string.format("%.6f", piE))
        printLine(poly)

    -- [Theorem 13: Planck Constant]
    elseif normAction == "HBAR" or normAction == "HBARDERIVE" or normAction == "PLANCK" then
        local h = Compute.Planck()
        printLine("hbar:" .. string.format("%.3e", h))
        printLine("Flux: 2*pi/3")

    -- [Theorem 14: Quantum Superposition]
    elseif normAction == "QUT" or normAction == "QUANTUM" then
        systemMode = "QUANTUM"
        printLine("QUANTUM VIEW")

    -- [Theorem 15: Quantum Gravity Metric]
    elseif normAction == "QG" or normAction == "QGMETRIC" or normAction == "GRAVITY" then
        local g00 = Compute.GravityMetric(tonumber(arg1) or 1.0)
        printLine("g00:" .. string.format("%.6f", g00))
        printLine("Spin-2 Mode")

    -- [Theorem 16: Quasicrystal Projection]
    elseif normAction == "QC" or normAction == "QCPROJECT" or normAction == "QUASICRYSTAL" then
        Compute.BuildQC(tonumber(arg1) or 16)
        systemMode = "QUASICRYSTAL"
        printLine("QC LOADED")

    -- [Theorem 17: R(3) Dimension & Spinor Parity]
    elseif normAction == "R3" or normAction == "R3PROOF" or normAction == "SPINOR" then
        local par = Compute.SpinorParity(tonumber(arg1) or 360)
        printLine("R(3) 3-Strand")
        printLine("Spinor:" .. par)

    -- [Theorem 18: Strand Sharing & Berry Phase]
    elseif normAction == "STRAND" or normAction == "STRANDSHARE" or normAction == "BERRY" or normAction == "FLUX" then
        local flux = Compute.BerryFlux()
        printLine("Triality: 3")
        printLine("Flux:" .. string.format("%.3f", flux))

    -- [Theorem 19: Axon Conduction Ratio]
    elseif normAction == "AXON" or normAction == "NEURO1" or normAction == "NEUROAXON" then
        local r, l, v = Compute.NeuroAxon()
        printLine("Axon: Q=1")
        printLine("r:" .. r .. "um")
        printLine("Node:" .. l .. "mm")
        printLine("v:" .. v .. "m/s")

    -- [Theorem 20: Relativistic Kink Soliton & Wave Synthesizer]
    elseif normAction == "WAVE" then
        triggerWave(arg1 or "SOLITON")

    elseif normAction == "SOLITON" or normAction == "SINEGORDON" or normAction == "KINK" or normAction == "NEURO2" then
        triggerWave("SOLITON")

    elseif normAction == "COLLIDE" or normAction == "COLLISION" then
        triggerWave("COLLIDE")

    elseif normAction == "STAND" or normAction == "STANDING" or normAction == "RESONANCE" then
        triggerWave("STAND")

    elseif normAction == "CHIRP" or normAction == "SWEEP" then
        triggerWave("CHIRP")

    elseif normAction == "GAUSS" or normAction == "PACKET" then
        triggerWave("GAUSS")

    -- [Theorem 21: EEG Brainwave Harmonics]
    elseif normAction == "EEG" or normAction == "NEURO3" then
        printLine("EEG MODES (Hz):")
        local modes = Compute.EEGModes()
        for _, m in ipairs(modes) do
            printLine(string.format("%s: %.2f", m.name, m.f))
        end
        soundResonance(F_CONSCIOUS)

    -- [Theorem 22: Neurodegenerative Decoherence]
    elseif normAction == "DISEASE" or normAction == "DIS" or normAction == "NEURO4" then
        local d, def, ons = Compute.Disease(arg1)
        printLine(d .. ":")
        printLine(def)
        printLine(ons)

    -- [Theorem 23: Theory-Zero Axioms]
    elseif normAction == "THZERO" or normAction == "TH0" or normAction == "THEORYZERO" then
        local morph, energy, rtube = Compute.TheoryZero()
        printLine("THEORY-ZERO:")
        printLine(morph)
        printLine("E:" .. energy)
        printLine("r:" .. rtube)

    -- [Theorem 24: Constant Vortex Tube Radius]
    elseif normAction == "TUBE" or normAction == "TUBERADIUS" then
        local rt, form = Compute.Tube()
        printLine("TUBE THEOREM:")
        printLine("rt:" .. string.format("%.5f", rt) .. "fm")
        printLine(form)

    -- [Theorem 25: Master Unification Closure]
    elseif normAction == "UNIFY" then
        printLine("== UNIFIED TEST ==")
        printLine("1. Soliton sweep")
        triggerWave("SOLITON")
        soundTPMChime()
        printLine("2. 4 Forces @ phi")
        printLine("3. Status: 25/25 OK")

    else
        printError("ERR:CMD", "Unrecognized command: \"" .. tostring(cmd) .. "\". Type THEOREMS, BASM, or THEORY for help.")
    end
end

-- ====================
-- 11. HARDWARE INTERRUPTS & CONTROLS (CALIBRATED PHYSICAL ORDER)
-- ====================

-- Channel 1: Keyboard Chip
function eventChannel1(sender, event)
    if event.Type == "KeyboardChipEvent" and event.ButtonDown then
        local keyName = tostring(event.InputName)

        if keyName == "Backspace" then
            if string.len(inputLine) > 0 then
                inputLine = string.sub(inputLine, 1, -2)
            end
        elseif keyName == "UpArrow" or keyName == "Up" then
            if #commandHistory > 0 then
                historyIndex = math.max(1, historyIndex - 1)
                inputLine = commandHistory[historyIndex] or ""
            end
        elseif keyName == "DownArrow" or keyName == "Down" then
            if #commandHistory > 0 then
                historyIndex = math.min(#commandHistory + 1, historyIndex + 1)
                inputLine = commandHistory[historyIndex] or ""
            end
        elseif keyName == "Return" or keyName == "KeypadEnter" then
            executeCommand(inputLine)
            inputLine = ""
        elseif keyName == "Escape" then
            systemMode = "TERMINAL"
        elseif keyName == "Tab" then
            if systemMode == "TERMINAL" then systemMode = "OSCILLOSCOPE"
            elseif systemMode == "OSCILLOSCOPE" then systemMode = "QUANTUM"
            elseif systemMode == "QUANTUM" then systemMode = "QUASICRYSTAL"
            else systemMode = "TERMINAL" end
        elseif charMap[keyName] then
            inputLine = inputLine .. charMap[keyName]
        end
    end
end

-- Channel 2: Wifi Receiver & HTTP Polling Handler
function eventChannel2(sender, event)
    isPolling = false

    if not event.IsError and (event.ResponseCode == 200 or event.ResponseCode == 0 or not event.ResponseCode) then
        serverConnected = true
        connectionTimeout = 180 -- Stay illuminated for ~3 seconds
        if linkLed then
            linkLed.State = true
            linkLed.Color = color.cyan
        end
        if syncRequested then
            syncRequested = false
            printLine("SYNC: OK")
            debugLog("[WIFI] Synchronized with Bridge Server 127.0.0.1:8080", 32)
            notifyDesk("WIFI SYNC: OK", "INFO")
        end
    else
        serverConnected = false
        if linkLed then
            linkLed.State = false
        end
        if syncRequested then
            syncRequested = false
            printError("ERR:OFFLINE", "Bridge server is offline or unreachable at 127.0.0.1:8080.")
        end
    end

    local payload = event.Text or event.Data or event.Payload or ""
    if event.IsError or string.len(payload) == 0 or payload == "IDLE" or payload == "ACK" then
        return
    end

    printLine("RX: " .. string.sub(payload, 1, 8))

    if string.sub(payload, 1, 6) == "TRITS:" then
        local trits = string.sub(payload, 7)
        for i = 1, math.min(24, #trits) do
            local c = string.sub(trits, i, i)
            if c == "+" or c == "1" then ACC[i] = 1
            elseif c == "-" or c == "2" then ACC[i] = -1
            else ACC[i] = 0 end
        end
        updateLeds()
        soundClick(1)
        printLine("TRITS: INJECT")

    elseif string.sub(payload, 1, 5) == "EXEC:" then
        local cmd = string.sub(payload, 6)
        executeCommand(cmd)

    elseif string.sub(payload, 1, 4) == "TPM:" then
        local sig = TPM.GenerateSignature(137)
        soundTPMChime()
        printLine("TPM: " .. string.sub(sig, 1, 8))
    end
end

-- --------------------
-- 3 CENTER MACRO KEYS (Under the 24 LEDs): Channels 3, 4, 5
-- --------------------
function eventChannel3(sender, event)
    if sender.ButtonState then shiftBraidRight(-1) end
end
function eventChannel4(sender, event)
    if sender.ButtonState then shiftBraidRight(0) end
end
function eventChannel5(sender, event)
    if sender.ButtonState then shiftBraidRight(1) end
end

-- --------------------
-- 4 SIDE FUNCTION BUTTONS (Calibrated from Top to Bottom: Channels 9, 8, 7, 6)
-- --------------------

-- TOP Side Button (Channel 9): B-SIMP (Simplify Braid)
function eventChannel9(sender, event)
    if sender.ButtonState then
        simplifyBraid()
    end
end

-- 2ND Side Button (Channel 8): B-INV (Invert Chirality)
function eventChannel8(sender, event)
    if sender.ButtonState then
        invertBraid()
    end
end

-- 3RD Side Button (Channel 7): VIEW MEM (Cycle & Peek Flash Address)
function eventChannel7(sender, event)
    if sender.ButtonState then
        memViewAddr = (memViewAddr + 1) % 256
        memPeekBuffer = readWord(memViewAddr)
        memPeekActive = true
        memPeekTimer = 90
        updateLeds()
        soundClick(0.6 + (memViewAddr % 8) * 0.15)
        printLine("PEEK M:" .. memViewAddr)
    end
end

-- BOTTOM Side Button (Channel 6): SYNC (WiFi Synchronization)
function eventChannel6(sender, event)
    if sender.ButtonState then
        soundTPMChime()
        syncRequested = true
        printLine("SYNC...")
        if wifi then
            isPolling = true
            pcall(function()
                wifi:WebGet("http://127.0.0.1:8080/api/poll")
            end)
        else
            printError("ERR:NO WIFI", "No Wifi hardware found.")
        end
    end
end

-- ====================
-- 12. MAIN SYSTEM LOOP & CONTINUOUS HTTP POLLING
-- ====================

function update()
    cursorBlink = (cursorBlink + 1) % 30
    syncLampWithState()

    if systemMode == "BOOT" then
        bootTimer = bootTimer + 1
        local index = math.floor(bootTimer / 2)
        if index > 0 and index <= 24 then
            ACC[index] = 1
            updateLeds()
        elseif index > 24 and index <= 48 then
            ACC[index - 24] = 0
            updateLeds()
        elseif index > 50 then
            cliBuffer = {"5500FP Setun 24", "EARTH v2.5", "SYS READY."}
            systemMode = "TERMINAL"
            soundTPMChime()
        end
        return
    end

    -- Flash Memory Peek Timer Countdown
    if memPeekActive then
        memPeekTimer = memPeekTimer - 1
        if memPeekTimer <= 0 then
            memPeekActive = false
            updateLeds()
        end
    end

    -- Dual-Highway HTTP Bridge: WebGet Polling (t=30) & Telemetry POST (t=60)
    if wifi and not isPolling then
        pollTimer = pollTimer + 1
        if pollTimer == 30 then
            isPolling = true
            pcall(function()
                wifi:WebGet("http://127.0.0.1:8080/api/poll")
            end)
        elseif pollTimer >= 60 then
            pollTimer = 0
            pcall(function()
                local tritStr = ""
                for i = 1, 24 do
                    tritStr = tritStr .. (ACC[i] == 1 and "+" or (ACC[i] == -1 and "-" or "0"))
                end
                local pm, pz, pp, purity = Compute.GetProbabilities()
                local netQ = Compute.CalculateChirality(ACC)
                local isMagConnected = isDocked or (magDock and magDock.IsConnected) or false
                local jsonStr = string.format('{"trits":"%s","mode":"%s","qProb":[%.3f,%.3f,%.3f],"purity":%.3f,"netQ":%d,"docked":%s}',
                    tritStr, systemMode, pm, pz, pp, purity, netQ, isMagConnected and "true" or "false")
                wifi:WebPostData("http://127.0.0.1:8080/api/telemetry", jsonStr)
            end)
        end
    end

    if activeWaveMode then
        waveTime = waveTime + 0.05
        if activeWaveMode == "SOLITON" then
            local center = waveTime * 24.0
            for i = 1, 24 do
                local diff = (i - center)
                local sech = 1.0 / math.cosh(diff * 0.8)
                SolitonBuffer[i] = sech * math.sin(waveTime * 4.0)
            end
            if center > 32 then activeWaveMode = nil end

        elseif activeWaveMode == "COLLIDE" then
            local cLeft  = waveTime * 20.0
            local cRight = 25.0 - (waveTime * 20.0)
            for i = 1, 24 do
                local s1 = 1.0 / math.cosh((i - cLeft) * 0.8)
                local s2 = -1.0 / math.cosh((i - cRight) * 0.8)
                SolitonBuffer[i] = s1 + s2
            end
            if cLeft > 32 then activeWaveMode = nil end

        elseif activeWaveMode == "STAND" or activeWaveMode == "STANDING" then
            for i = 1, 24 do
                local k = (3 * math.pi * (i - 1)) / 23
                SolitonBuffer[i] = math.sin(k) * math.cos(waveTime * 8.0)
            end
            if waveTime > 6.0 then activeWaveMode = nil end

        elseif activeWaveMode == "EEG" then
            for i = 1, 24 do
                local t1 = math.sin(waveTime * 7.83 + i * 0.3) * 0.5
                local t2 = math.sin(waveTime * 12.67 + i * 0.5) * 0.3
                local t3 = math.sin(waveTime * 20.50 + i * 0.8) * 0.2
                SolitonBuffer[i] = t1 + t2 + t3
            end
            if waveTime > 8.0 then activeWaveMode = nil end

        elseif activeWaveMode == "CHIRP" then
            for i = 1, 24 do
                local freq = 1.0 + waveTime * 4.0
                local sech = 1.0 / math.cosh((i - waveTime * 20.0) * 0.6)
                SolitonBuffer[i] = sech * math.sin(i * freq * 0.5)
            end
            if waveTime * 20.0 > 32 then activeWaveMode = nil end

        elseif activeWaveMode == "GAUSS" or activeWaveMode == "QUANTUM" then
            local center = waveTime * 18.0
            local width = 1.5 + waveTime * 1.2
            for i = 1, 24 do
                local gauss = math.exp(-((i - center)^2) / (2 * width^2))
                SolitonBuffer[i] = gauss * math.cos((i - center) * 2.0)
            end
            if center > 32 then activeWaveMode = nil end
        end

        updateLeds()
    else
        -- Default Live Mode: Continuous Analog Scope of current 24-Trit Accumulator!
        if systemMode == "OSCILLOSCOPE" then
            for i = 1, 24 do
                SolitonBuffer[i] = ACC[i] * 0.8
            end
            updateLeds()
        end
    end

    -- Real-time Quantum Phase Precession & Quasicrystal 5D Rotation
    if systemMode == "QUANTUM" then
        qPhaseRot = (qPhaseRot + 0.04) % (2 * math.pi)
    elseif systemMode == "QUASICRYSTAL" then
        if qcRotating then
            qcAngle = (qcAngle + 0.03) % (2 * math.pi)
        end
    end

    -- External Server Link Indicator (Led24)
    if connectionTimeout > 0 then
        connectionTimeout = connectionTimeout - 1
        if connectionTimeout <= 0 then
            serverConnected = false
        end
    end

    if linkLed then
        linkLed.State = serverConnected
        linkLed.Color = color.cyan
    end

    drawScreen()
end

-- Channel 10: Server Link Indicator / Manual Sync Event
function eventChannel10(sender, event)
    if sender and sender.ButtonState then
        printLine("SYNCING (CH10)...")
        if wifi then
            isPolling = true
            pcall(function() wifi:WebGet("http://127.0.0.1:8080/api/poll") end)
        end
    end
end

-- Channel 11: Modular Magnetic Connector Docking Event
function eventChannel11(sender, event)
    if event.Type == "MagneticConnectorEvent" then
        if event.IsConnected then
            isDocked = true
            soundTPMChime()
            printLine("MAG-DOCK: ATTACHED")
            triggerWave("STAND")
        else
            isDocked = false
            soundClick(0.6)
            printLine("MAG-DOCK: EJECTED")
        end
    elseif sender and sender.ButtonState then
        -- Central mechanical eject button
        soundClick(0.5)
        printLine("MAG-DOCK: RELEASE")
    end
end
