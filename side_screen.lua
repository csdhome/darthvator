local json = require('dkjson')

-- CONSTANTS ----------
constants = {}
constants.deg2rad = 0.0174532925199
constants.rad2deg = 57.2957795130

-- helper functions ---
function getData()
    return json.decode(getInput()) or {}
end

function sendData(data)
    setOutput(json.encode(data))
end

-- UI ----------------
UI = {}
UI.__index = UI;

function UI.new(layer, layer2, layer3, f_xxs, f_xs, f_s, f_m, b_t, sw, sh)
    local self = setmetatable({}, UI)
    self.layer = layer
    self.layer2 = layer2
    self.layer3 = layer3
    self.f_xxs = f_xxs
    self.f_xs = f_xs
    self.f_s = f_s
    self.f_m = f_m
    self.b_t = b_t
    self.sw, self.sh = sw, sh
    self.tempAlt = ""

    self.dR = 0
    self.dR2 = 0
    self.dR3 = 0
    self.vvSign = 1

    self.t = getTime()
    self.lt = self.t
    self.dt = 0

    self.frame = 0

    self.targetFloor = 0
    self.targetAltitude = 0

    return self
end

function UI.drawFuelBars(self, layer, font, atmo, space, x, y, w, h, sp)
    local cnt = 0
    local tM = 30
    if atmo ~= nil then
        for i, tank in ipairs(atmo) do
            local p = tank.c_volume * 100 / tank.volume
            setNextFillColor(layer, 1, 33 / 255, 6 / 255, 0.1)
            addBox(layer, x + tM, y + i * sp, w, h)
            setNextFillColor(layer, 1, 33 / 255, 6 / 255, 0.5)
            addBox(layer, x + tM, y + i * sp, w * p / 100, h)
            setNextFillColor(layer, 1, 33 / 255, 6 / 255, 1)
            setNextTextAlign(layer, AlignH_Center, AlignV_Middle)
            addText(layer, font, string.format("AF%d", i), x - 20, y + i * sp + h / 2)

            local c = w / 10
            local zw = w / c
            for z = 1, c - 1 do
                local zww = zw / 7
                setNextFillColor(layer, 0, 0, 0, 1)
                addBox(layer, x + tM + z * zw, y + i * sp, zww, h)
            end
            cnt = i
        end
    end

    if space ~= nil then
        for i, tank in ipairs(space) do
            local p = tank.c_volume * 100 / tank.volume
            setNextFillColor(layer, 1, 33 / 255, 6 / 255, 0.1)
            addBox(layer, x + tM, y + i * sp, w, h)
            setNextFillColor(layer, 1, 33 / 255, 6 / 255, 0.5)
            addBox(layer, x + tM, y + i * sp, w * p / 100, h)
            setNextFillColor(layer, 1, 33 / 255, 6 / 255, 1)
            setNextTextAlign(layer, AlignH_Center, AlignV_Middle)
            addText(layer, font, string.format("AF%d", i), x - 20, y + i * sp + h / 2)

            local c = w / 10
            local zw = w / c
            for z = 1, c - 1 do
                local zww = zw / 7
                setNextFillColor(layer, 0, 0, 0, 1)
                addBox(layer, x + tM + z * zw, y + i * sp, zww, h)
            end
            cnt = i
        end
    end
end

function UI.loop(self)
    self.t = getTime()
    self.dt = math.max(self.t - self.lt, 0.0001)
    self.lt = self.t

    -- update
    local data = getData()

    -- DRAW ----------------------------------------------------------
    -- BG
    local bg = loadImage("assets.prod.novaquark.com/64852/f9c9946c-9705-4e98-b604-ef00379458bb.png")
    setNextRotation(self.layer, 90 * constants.deg2rad)
    addImage(self.layer, bg, 0, 0, sw, sh)

    self:drawFuelBars(self.layer2, self.f_s,
                      data.atmoFuel, data.spaceFuel,
                      320, -150, 390, 60, 80)
end

layer = createLayer()
layer2 = createLayer()
layer3 = createLayer()
sw, sh = getResolution()
baseFontSize = math.floor(sh / 20)
baseThick = math.floor(sh / 204.3)
font_xxs = loadFont("RobotoCondensed", baseFontSize - 14)
font_xs = loadFont("RobotoCondensed", baseFontSize - 6)
font_s = loadFont("RobotoCondensed", baseFontSize + 4)
font_m = loadFont("RobotoMono-Bold", baseFontSize + 6)

-- rotate buy n degrees
local deg = 90
local rad = constants.deg2rad * deg

setLayerOrigin(layer, sw / 2 , sh / 2)
setLayerOrigin(layer2, sw / 2 , sh / 2)
setLayerOrigin(layer3, sw / 2 , sh / 2)
setLayerRotation(layer, rad)
setLayerRotation(layer2, rad)
setLayerRotation(layer3, rad)

if not init then
    init = true
    ui = UI.new(layer, layer2, layer3, font_xxs, font_xs, font_s, font_m, baseThick, sw, sh)
end

-- main loop
ui:loop()
requestAnimationFrame(1)