local json = require('dkjson')
local vec3 = require('cpml/vec3')

-- helper functions ---
function getData()
    return json.decode(getInput()) or {}
end

function sendData(data)
    setOutput(json.encode(data))
end

-- Sensor square button ------
button = {}
button.__index = button;

function button.new(layer, x, y, width, height, font, text, hint, sx, sy)
    local self = setmetatable({}, button)
    self.layer = layer
    self.x = x
    self.y = y
    self.width = width
    self.height = height
    self.dColor = { 1, 1, 1, 0 }
    self.hColor = { 1, 0.9, 0.9, 0.1 }
    self.pColor = { 1, 1, 1, 0.3 }
    self.tColor = {1, 1, 1, 1}
    self.state = false
    self.hover = false
    self.text = text
    self.font = font
    self.hint = hint

    return self
end

function button.inBounds(self, x, y)
    if x >= self.x and x <= self.x + self.width and y >= self.y and y <= self.y + self.height then
        return true
    end
    return false
end

function button.setState(self, state)
    self.state = state
end

function button.getState(self)
    return self.state
end

function button.toggle(self)
    self.state = not self.state
end

function button.draw(self)
    local color = self.dColor
    if self.state then
        color = self.pColor
    elseif self.hover or self.focus then
        color = self.hColor
    end
    setNextFillColor(self.layer, color[1], color[2], color[3], color[4])
    addBox(self.layer, self.x, self.y, self.width, self.height)

    if self.text ~= nil then
        setNextFillColor(self.layer, self.tColor[1], self.tColor[2], self.tColor[3], self.tColor[4])
        setNextTextAlign(self.layer, AlignH_Center, AlignV_Middle)
        addText(self.layer, self.font, self.text, self.x + self.width / 2, self.y + self.height / 2)
    end
    if self.hover and self.hint ~= nil then
        local cx, cy = getCursor()
        local hw, hh = getTextBounds(font_xxs, self.hint)
        local hp = 10
        local shift = 10
        local shifty = -(hh + hp * 2)
        if sx ~= nil then
            shift = sx
        end
        if sy ~= nil then
            shifty = sy
        end
        cx = cx + shift
        cy = cy + shifty

        hw = hw + hp * 2
        hh = hh + hp * 2

        local hfColor = {self.hColor[1] / 4, self.hColor[2] / 4, self.hColor[3] / 4, 0.6}
        setNextStrokeColor(hintLayer, hfColor[1], hfColor[2], hfColor[3], hfColor[4])
        addLine(hintLayer, cx - 1, cy - 1, cx - 1 + hw + 2, cy - 1)
        setNextStrokeColor(hintLayer, hfColor[1], hfColor[2], hfColor[3], hfColor[4])
        addLine(hintLayer, cx - 1, cy - 1 + hh + 2, cx - 1 + hw + 2, cy - 1 + hh + 2)
        setNextStrokeColor(hintLayer, hfColor[1], hfColor[2], hfColor[3], hfColor[4])
        addLine(hintLayer, cx - 1, cy - 1, cx - 1, cy - 1 + hh + 2)
        setNextStrokeColor(hintLayer, hfColor[1], hfColor[2], hfColor[3], hfColor[4])
        addLine(hintLayer, cx - 1 + hw + 2, cy - 1, cx - 1 + hw + 2, cy - 1 + hh + 2)

        setNextFillColor(hintLayer, 0.1, 0.01, 0.01, 0.9)
        addBox(hintLayer, cx, cy, hw, hh)
        setNextTextAlign(hintLayer, AlignH_Left, AlignV_Top)
        setNextFillColor(hintLayer, self.hColor[1], self.hColor[2], self.hColor[3], self.hColor[4])
        addText(hintLayer, font_xxs, self.hint, cx + hp, cy + hp)
    end
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

    -- buttons
    self.EBbtn = button.new(self.layer3, 67, 80, 230, 150, self.f_m, "EB", "Emergency Brake", 10, -50)
    self.EBbtn.dColor = {1, 1/255, 1/255, 0.15}
    self.EBbtn.hColor = {1, 1/255, 1/255, 0.5}
    self.EBbtn.pColor = {1, 1/255, 1/255, 1}
    self.EBbtn.tColor = {1, 38/255, 6/255, 1}

    self:initNumboard(layer3, 50, 10, 36 + 30, self.sh / 2, f_xs, 
                    {1, 38/255, 6/255, 0.15}, 
                    {1, 38/255, 6/255, 0.5}, 
                    {1, 38/255, 6/255, 1}, 
                    {1, 1, 1, 1})
                    --{1, 152/255, 1, 1})

    return self
end

function UI.drawFuelBars(self, layer, font, atmo, space, x, y, w, h, sp)
    local cnt = 0
    local tM = 30
    if atmo ~= nil then
        for i, tank in ipairs(atmo) do
            local p = tank.c_volume * 100 / tank.volume
            setNextFillColor(layer, 1, 33 / 255, 6/255, 0.1)
            addBox(layer, x + tM, y + i * sp, w, h)
            setNextFillColor(layer, 1, 33 / 255, 6/255, 0.5)
            addBox(layer, x + tM, y + i * sp, w * p / 100, h)
            setNextFillColor(layer, 1, 33 / 255, 6/255, 1)
            addText(layer, font, string.format("AF%d", i), x, y + i * sp + 7)

            local c = w/10
            local zw = w / c
            for z=1,c-1 do
                local zww = zw / 7
                setNextFillColor(layer, 0, 0, 0, 1)
                addBox(layer, x + tM + z * zw, y + i * sp, zww, h)
            end
            cnt = i
        end
    end

    if atmo ~= nil then
        for i, tank in ipairs(space) do
            local j = i + cnt
            local p = tank.c_volume * 100 / tank.volume
            --{1, 38/255, 6/255, 1}
            setNextFillColor(layer, 1, 33 / 255, 6/255, 0.1)
            addBox(self.layer2, x + tM, y + j * sp, w, h)
            setNextFillColor(layer, 1, 33 / 255, 6/255, 0.5)
            addBox(layer, x + tM, y + j * sp, w * p / 100, h)
            setNextFillColor(layer, 1, 33 / 255, 6/255, 1)
            addText(layer, font, string.format("SF%d", j - cnt), x, y + j * sp + 7)

            local c = w/10
            local zw = w / c
            for z=1,c-1 do
                local zww = zw / 7
                setNextFillColor(layer, 0, 0, 0, 1)
                addBox(layer, x + tM + z * zw, y + j * sp, zww, h)
            end
        end
    end
end

function UI.drawVelocityBars(self, data, x, y, bw, bh)
    local l1, l2, l3 = self.layer, self.layer2, self.layer3
    local bm = 10
    if data.vv ~= nil and data.maxVel ~= nil and data.a ~= nil and data.g ~= nil then
        -- setNextFillColor(l1, 1, 1, 1, 0.1)
        -- addBox(l1, x, y, w, h)

        -- VV
        altDif = data.dAlt - data.alt
        self.vvSign = math.abs(altDif) / altDif
        local maxVel = data.maxVel

        local bc = bh / 2
        local tbh = bc - 10
        local p = 0
        local pbh = tbh * p
        if maxVel ~= 0 and data.vv ~= 0 then
            p = data.vv / maxVel
            if p > 1 then p = 1 end
            pbh = tbh / 2 * p
        end

        setNextFillColor(l2, 1, 33 / 255, 6/255, 0.1)
        addBox(l2, x, y, bw, tbh)
        setNextFillColor(l2, 1, 33 / 255, 6/255, 0.1)
        addBox(l2, x, y + bc + 10, bw, tbh)
        -- setNextFillColor(l1, 1, 33 / 255, 6/255, 0.5)
        setNextFillColor(l2, 33 / 255, 1, 6/255, 0.5)
        if altDif > 0 then
            addBox(l2, x, y + bc - 10 - pbh, bw, pbh)
        else
            addBox(l2, x, y + bc + 10, bw, pbh)
        end
        setNextFillColor(l3, 1, 33 / 255, 6/255, 1)
        setNextTextAlign(l3, AlignH_Center, AlignV_Middle)
        addText(l3, self.f_xxs, "V", x + bw / 2, y + bh + 20)
        setNextStrokeColor(l2, 1, 33 / 255, 6/255, 1)
        addLine(l2, x, y + bh / 2, x + bw, y + bh / 2)

        local c = math.floor(bh/10)
        local zw = bh / c
        setDefaultFillColor(l2, Shape_Box, 0, 0, 0, 1)
        for z=1,c-1 do
            local zww = math.floor(zw / 7)
            addBox(l2, x, y + z * zw - zww, bw, zww)
        end

        -- A
        p = 0
        pbh = bh * p
        local maxA = 12
        if data.a ~= 0 then
            p = data.a / maxA
            if p > 1 then p = 1 end
            pbh = tbh / 2 * p
        end
        --addText(l1, self.f_xs, string.format("p: %.2f, vv: %.2f, vvM: %.2f", p, data.vv, data.maxVel), 100, 160)
        setNextFillColor(l2, 1, 33 / 255, 6/255, 0.1)
        --setNextFillColor(l1, 33 / 255, 1, 6/255, 0.5)
        addBox(l2, x + bw + bm, y, bw, tbh)
        --addBox(l1, x + bw + bm, y, bw, bh)
        setNextFillColor(l2, 33 / 255, 1, 6/255, 1)
        addBox(l2, x + bw + bm, y + bc - 10 - pbh, bw, pbh)
        --addBox(l1, x + bw + bm, y + bh - pbh, bw, pbh)
        setNextFillColor(l3, 1, 33 / 255, 6/255, 1)
        setNextTextAlign(l3, AlignH_Center, AlignV_Middle)
        addText(l3, self.f_xxs, "A", x + bw + bm + bw / 2, y + bh + 20)
        setNextStrokeColor(l2, 1, 33 / 255, 6/255, 1)
        addLine(l2, x + bw + bm, y + bh / 2, x + bw + bm + bw, y + bh / 2)

        local c = math.floor(bh/10)
        local zw = bh / c
        setDefaultFillColor(l2, Shape_Box, 0, 0, 0, 1)
        for z=1,c-1 do
            local zww = math.floor(zw / 7)
            addBox(l2, x + bw + bm, y + z * zw - zww, bw, zww)
        end

        -- B
        p = 0
        pbh = bh * p
        if data.ba ~= 0 then
            p = data.ba / maxA
            if p > 1 then p = 1 end
            pbh = tbh / 2 * p
        end
        setNextFillColor(l2, 1, 33 / 255, 6/255, 0.1)
        addBox(l2, x + bw + bm, y + bc + 10, bw, tbh)
        setNextFillColor(l2, 1, 0, 6/255, 1)
        addBox(l2, x + bw + bm, y + bc + 10, bw, pbh)

        local c = math.floor(bh/10)
        local zw = bh / c
        setDefaultFillColor(l2, Shape_Box, 0, 0, 0, 1)
        for z=1,c-1 do
            local zww = math.floor(zw / 7)
            addBox(l2, x + bw + bm, y + z * zw - zww, bw, zww)
        end

        -- G
        p = 0
        pbh = bh * p
        if data.g ~= 0 then
            p = data.g / 9.8
            if p > 1 then p = 1 end
            pbh = bh * p
        end
        --addText(l1, self.f_xs, string.format("p: %.2f, vv: %.2f, vvM: %.2f", p, data.vv, data.maxVel), 100, 160)
        setNextFillColor(l2, 1, 33 / 255, 6/255, 0.1)
        addBox(l2, x + bw * 2 + bm * 2, y, bw, bh)
        --color = {33 / 255, 1, 6 / 255, 0.2}
        -- setNextFillColor(l1, 33 / 255, 1, 6/255, 0.5)
        setNextFillColor(l2, 1, 33 / 255, 6/255, 0.5)
        addBox(l2, x + bw * 2 + bm * 2, y + bh - pbh, bw, pbh)
        setNextFillColor(l3, 1, 33 / 255, 6/255, 1)
        setNextTextAlign(l3, AlignH_Center, AlignV_Middle)
        addText(l3, self.f_xxs, "G", x + bw * 2 + bm * 2 + bw / 2, y + bh + 20)

        local c = math.floor(bh/10)
        local zw = bh / c
        setDefaultFillColor(l2, Shape_Box, 0, 0, 0, 1)
        for z=1,c-1 do
            local zww = math.floor(zw / 7)
            addBox(l2, x + bw * 2 + bm * 2, y + z * zw - zww, bw, zww)
        end
    end
end

function UI.initFloors(self, data, x, y, bs, bm)
    if self.floorsLoaded then
        return
    else
        if data.fl ~= nil then
            for i, e in pairs(data.fl) do
                self["floor"..i] = button.new(self.layer3, x, y - i * (bs + bm), bs * 2, bs, self.f_xs, i, string.format("%.2f", e))
                self["floor"..i].dColor = {1, 33 / 255, 6/255, 0.15}
                self["floor"..i].hColor = {1, 33 / 255, 6/255, 0.5}
                self["floor"..i].pColor = {1, 33 / 255, 6/255, 1}
                self["floor"..i].value = e
                if i > 1 then
                    self["rfloor"..i] = button.new(self.layer3, x + bs * 2 + bm, y - i * (bs + bm), bs, bs, self.f_s, "-", "remove floor")
                    self["rfloor"..i].dColor = {1, 33 / 255, 6/255, 0.15}
                    self["rfloor"..i].hColor = {1, 33 / 255, 6/255, 0.5}
                    self["rfloor"..i].pColor = {1, 33 / 255, 6/255, 1}
                    self["rfloor"..i].value = e
                end
            end
        end
        self.addFloorBtn = button.new(self.layer3, x + bs * 2 + bm, y - 1 * (bs + bm), bs, bs, self.f_s, "+", "add floor with the current altitude")
        self.addFloorBtn.dColor = {1, 33 / 255, 6/255, 0.15}
        self.addFloorBtn.hColor = {1, 33 / 255, 6/255, 0.5}
        self.addFloorBtn.pColor = {1, 33 / 255, 6/255, 1}
        self.floorsLoaded = true
    end
end

function UI.drawFloors(self, data)
    if data.fl ~= nil then
        for i, e in pairs(data.fl) do
            if i == self.targetFloor then
                self["floor"..i].focus = true
            end
            self["floor"..i]:draw()
            if i > 1 then
                self["rfloor"..i]:draw()
            end
        end
        self.addFloorBtn:draw()
    end
end

function UI.updateFloors(self, data)
    if data.fl ~= nil then
        local cx, cy = getCursor()
        for i, e in pairs(data.fl) do
            if self["floor"..i]:inBounds(cx, cy) then
                self["floor"..i].hover = true
                if getCursorReleased() then
                    self["floor"..i]:setState(true)
                end
            end
            if i > 1 then
                if self["rfloor"..i]:inBounds(cx, cy) then
                    self["rfloor"..i].hover = true
                    if getCursorReleased() then
                        self["rfloor"..i]:setState(true)
                    end
                end
            end
        end
        if self.addFloorBtn:inBounds(cx, cy) then
            self.addFloorBtn.hover = true
            if getCursorReleased() then
                self.addFloorBtn:setState(true)
            end
        end
    end
end

function UI.resetFloors(self, data)
    if data.fl ~= nil then
        for i, e in pairs(data.fl) do
            self["floor"..i].hover = false
            self["floor"..i]:setState(false)
            if self["floor"..i].focus ~= nil then
                self["floor"..i].focus = false
            end
            if i > 1 then
                self["rfloor"..i].hover = false
                self["rfloor"..i]:setState(false)
            end
        end
        self.addFloorBtn.hover = false
        self.addFloorBtn:setState(false)
    end
end

-- bs: button side
-- bm: button margin
-- x: x of the top left corner
-- y: y of the top left
-- dColor: default btn color
-- hColor: hover btn color
-- pColor: pressed btn color
function UI.initNumboard(self, layer, bs, bm, x, y, font, dColor, hColor, pColor, tColor)
    local bs = bs or 64
    local bm = bm or 16
    local sH = y or 0
    local sW = x or 0
    local rS = bs + bm

    self.btn7 = button.new(layer, sW + rS * 0, sH, bs, bs, font, "7")
    self.btn8 = button.new(layer, sW + rS * 1, sH, bs, bs, font, "8")
    self.btn9 = button.new(layer, sW + rS * 2, sH, bs, bs, font, "9")

    self.btn4 = button.new(layer, sW + rS * 0, sH + rS * 1, bs, bs, font, "4")
    self.btn5 = button.new(layer, sW + rS * 1, sH + rS * 1, bs, bs, font, "5")
    self.btn6 = button.new(layer, sW + rS * 2, sH + rS * 1, bs, bs, font, "6")

    self.btn1 = button.new(layer, sW + rS * 0, sH + rS * 2, bs, bs, font, "1")
    self.btn2 = button.new(layer, sW + rS * 1, sH + rS * 2, bs, bs, font, "2")
    self.btn3 = button.new(layer, sW + rS * 2, sH + rS * 2, bs, bs, font, "3")

    self.btnSign = button.new(layer, sW + rS * 0, sH + rS * 3, bs, bs, font, "+/-")
    self.btn0 = button.new(layer, sW + rS * 1, sH + rS * 3, bs, bs, font, "0")
    self.btnDec = button.new(layer, sW + rS * 2, sH + rS * 3, bs, bs, font, ".")

    self.btnBack = button.new(layer, sW + rS * 3, sH + rS * 0, bs, bs, font, "<-")
    self.btnCancel = button.new(layer, sW + rS * 3, sH + rS * 1, bs, bs, font, "x")
    self.btnAccept = button.new(layer, sW + rS * 3, sH + rS * 2, bs, bs * 2 + bm, font, "v")

    for i = 0, 9 do
        self["btn" .. i].dColor = dColor
        self["btn" .. i].hColor = hColor
        self["btn" .. i].pColor = pColor
        self["btn" .. i].tColor = tColor
    end

    self.btnSign.dColor = dColor
    self.btnSign.hColor = hColor
    self.btnSign.pColor = pColor
    self.btnSign.tColor = tColor
    self.btn0.dColor = dColor
    self.btn0.hColor = hColor
    self.btn0.pColor = pColor
    self.btn0.tColor = tColor
    self.btnDec.dColor = dColor
    self.btnDec.hColor = hColor
    self.btnDec.pColor = pColor
    self.btnDec.tColor = tColor
    self.btnBack.dColor = dColor
    self.btnBack.hColor = hColor
    self.btnBack.pColor = pColor
    self.btnBack.tColor = tColor
    self.btnCancel.dColor = dColor
    self.btnCancel.hColor = hColor
    self.btnCancel.pColor = pColor
    self.btnCancel.tColor = tColor
    self.btnAccept.dColor = dColor
    self.btnAccept.hColor = hColor
    self.btnAccept.pColor = pColor
    self.btnAccept.tColor = tColor
end

function UI.drawNumboard(self)
    for i = 0, 9 do
        self["btn" .. i]:draw()
    end
    self.btnAccept:draw()
    self.btnCancel:draw()
    self.btnSign:draw()
    self.btnDec:draw()
    self.btnBack:draw()
end

function UI.resetNumboardState(self)
    for i = 0, 9 do
        self["btn" .. i].hover = false
        self["btn" .. i]:setState(false)
    end
    self.btnAccept.hover = false
    self.btnCancel.hover = false
    self.btnSign.hover = false
    self.btnDec.hover = false
    self.btnBack.hover = false
    self.btnAccept:setState(false)
    self.btnCancel:setState(false)
    self.btnSign:setState(false)
    self.btnDec:setState(false)
    self.btnBack:setState(false)
end

function UI.updateNumboard(self)
    local cx, cy = getCursor()
    local data = getData()

    for i = 0, 9 do
        if self["btn" .. i]:inBounds(cx, cy) then
            self["btn" .. i].hover = true
            if getCursorReleased() then
                self["btn" .. i]:setState(true)
            end
        end
    end

    if self.btnAccept:inBounds(cx, cy) then
        self.btnAccept.hover = true
        if getCursorReleased() then
            self.btnAccept:setState(true)
        end
    end
    if self.btnCancel:inBounds(cx, cy) then
        self.btnCancel.hover = true
        if getCursorReleased() then
            self.btnCancel:setState(true)
        end
    end

    if self.btnSign:inBounds(cx, cy) then
        self.btnSign.hover = true
        if getCursorReleased() then
            self.btnSign:setState(true)
        end
    end
    if self.btnDec:inBounds(cx, cy) then
        self.btnDec.hover = true
        if getCursorReleased() then
            self.btnDec:setState(true)
        end
    end
    if self.btnBack:inBounds(cx, cy) then
        self.btnBack.hover = true
        if getCursorReleased() then
            self.btnBack:setState(true)
        end
    end
end

function UI.drawAxis(self, data)
    local l, l2 = self.layer2, self.layer3
    local sw, sh = self.sw, self.sh
    local eH = 40
    local eW = 120
    local sX = sw / 2 + 70
    local sY = 57 + eH / 2 -- top
    local length = sh - (57 + eH / 2) * 2

    -- axis
    setNextStrokeColor(l, 1, 33 / 255, 6/255, 1)
    addLine(l, sX, sY, sX, sY + length )
    setNextStrokeColor(l, 1, 33 / 255, 6/255, 1)
    addLine(l, sX - eW / 2, sY, sX + eW / 2, sY )
    setNextStrokeColor(l, 1, 33 / 255, 6/255, 1)
    addLine(l, sX - eW / 2, sY + length, sX + eW / 2, sY + length)

    -- elevator
    local eX, eY = sX - eW / 2, sY + length - eH
    local altDif = 0
    local goUp, goDown = false, false
    local path = length - eH

    if data.dAlt ~= nil then
        altDif = data.dAlt - data.alt
        self.vvSign = math.abs(altDif) / altDif

        if data.TD ~= nil then
            if altDif > 0 then
                goUp = true
            else
                goUp = false
            end
            goDown = not goUp

            local cPos = path * math.abs(altDif) / data.TD
            if goUp then
                eY = sY + cPos
            elseif goDown then
                eY = eY - cPos
            end
        end

        if eY < sY then eY = sY end
        if eY > sY + length - eH then eY = sY + length - eH end

        setNextFillColor(l, 1, 33 / 255, 6 / 255, 1)
        addBoxRounded(l, eX, eY, eW, eH, 4)
        setNextFillColor(l2, 0, 0, 0, 1)
        addBoxRounded(l2, eX + 1, eY + 1, eW - 2, eH - 2, 3)

        -- alt
        if data.alt ~= nil then
            local alt = data.alt
            local str = "m"
            if alt > 99 * 1000 * 200 then
                alt = alt / (1000 * 200)
                str = "su"
            elseif alt > 1000 then
                alt = alt / 1000
                str = "km"
            end
            setNextFillColor(l2, 1, 33 / 255, 6 / 255, 1)
            setNextTextAlign(l2, AlignH_Center, AlignV_Middle)
            addText(l2, self.f_xs, string.format("%.2f%s", alt, str), eX + eW / 2, eY + eH / 2)
        end
    end

end

function UI.drawDeviation(self, data, x, y, w, h)
    local l1, l2, l3 = self.layer, self.layer2, self.layer3
    local f = self.f_xs
    local deg2rad = 0.0174532925199
    local rad2deg = 57.2957795130
    -- BG -- 1, 33 / 255, 6/255, 1

    setNextFillColor(l3, 1, 33 / 255, 6/255, 1)
    setNextTextAlign(l3, AlignH_Right, AlignV_Top)
    addText(l3, self.f_xs, "Dev:", x + w - 80, y + 10)
    setNextFillColor(l3, 1, 33 / 255, 6/255, 1)
    setNextTextAlign(l3, AlignH_Right, AlignV_Top)
    addText(l3, self.f_xs, string.format("%.2f", data.cV), x + w - 10, y + 10)
    -- setNextFillColor(l1, 1, 33 / 255, 6/255, 1)
    -- setNextTextAlign(l1, AlignH_Left, AlignV_Top)
    -- addText(l1, self.f_xs, "p:", x + w + 20, y + 30)
    -- setNextFillColor(l1, 1, 33 / 255, 6/255, 1)
    -- setNextTextAlign(l1, AlignH_Right, AlignV_Top)
    -- addText(l1, self.f_xs, string.format("%.2f", data.p), x + w + 120, y + 30)
    -- setNextFillColor(l1, 1, 33 / 255, 6/255, 1)
    -- setNextTextAlign(l1, AlignH_Left, AlignV_Top)
    -- addText(l1, self.f_xs, "d:", x + w + 20, y + 60)
    -- setNextFillColor(l1, 1, 33 / 255, 6/255, 1)
    -- setNextTextAlign(l1, AlignH_Right, AlignV_Top)
    -- addText(l1, self.f_xs, string.format("%.2f", data.d), x + w + 120, y + 60)

    setNextFillColor(l2, 1, 33 / 255, 6/255, 1)
    addBox(l2, x, y, w, h)
    setNextFillColor(l2, 0, 0, 0, 1)
    addBox(l2, x + 1, y + 1, w - 2, h - 2)

    local color = {33 / 255, 1, 6 / 255, 0.2}
    color[1] = color[1] + data.cV * 0.001
    if color[1] > 1 then color[1] = 1 end
    if color[1] < 33 / 255 then color[1] = 33 / 255 end
    color[2] = color[2] - data.cV * 0.1
    if color[2] > 1 then color[2] = 1 end
    if color[2] < 33 / 255 then color[2] = 33 / 255 end

    local cx, cy = x + w / 2, y + h / 2
    -- lines go clockwise
    local xp = x - cx
    local yp = y - cy
    local r = math.sqrt(xp * xp + yp * yp)
    r = r - 3
    local rMax = r
    -- 1st
    local a = 45 * deg2rad
    local rx1 = cx + r * math.cos(a)
    local ry1 = cy + r * math.sin(a)
    -- setNextStrokeColor(l2, 1, 33 / 255, 6/255, 1)
    setNextStrokeColor(l2, color[1], color[2], color[3], color[4])
    addLine(l2, cx, cy, rx1, ry1)
    a = 135 * deg2rad
    local rx2 = cx + r * math.cos(a)
    local ry2 = cy + r * math.sin(a)
    setNextStrokeColor(l2, color[1], color[2], color[3], color[4])
    addLine(l2, cx, cy, rx2, ry2)
    a = 225 * deg2rad
    local rx3 = cx + r * math.cos(a)
    local ry3 = cy + r * math.sin(a)
    setNextStrokeColor(l2, color[1], color[2], color[3], color[4])
    addLine(l2, cx, cy, rx3, ry3)
    a = 315 * deg2rad
    local rx4 = cx + r * math.cos(a)
    local ry4 = cy + r * math.sin(a)
    setNextStrokeColor(l2, color[1], color[2], color[3], color[4])
    addLine(l2, cx, cy, rx4, ry4)

    -- squares
    local r1, r2, r3 = 0, 0, 0
    local vv = data.vv
    local koef = 0.001
    if self.dR == 0 and self.dR2 == 0 and self.dR3 == 0 then
        self.dR2 = rMax / 3
        self.dR3 = rMax / 3 * 2
    end
    local vvDx = vv * koef
    self.dR = self.dR + vvDx
    self.dR2 = self.dR2 + vvDx
    self.dR3 = self.dR3 + vvDx

    if self.dR > rMax then
        self.dR = 0
    end
    if self.dR2 > rMax then
        self.dR2 = 0
    end
    if self.dR3 > rMax then
        self.dR3 = 0
    end

    if self.vvSign > 0 then
        r1 = r - self.dR
        r2 = r - self.dR2
        r3 = r - self.dR3
    end
    if self.vvSign < 0 then
        r1 = 0 + self.dR
        r2 = 0 + self.dR2
        r3 = 0 + self.dR3
    end

    setNextFillColor(l3, 1, 33 / 255, 6 / 255, 1)
    setNextTextAlign(l3, AlignH_Center, AlignV_Middle)

    a = 45 * deg2rad
    local sx1 = cx + r1 * math.cos(a)
    local sy1 = cy + r1 * math.sin(a)
    local sx11 = cx + r2 * math.cos(a)
    local sy11 = cy + r2 * math.sin(a)
    local sx21 = cx + r3 * math.cos(a)
    local sy21 = cy + r3 * math.sin(a)
    a = 135 * deg2rad
    local sx2 = cx + r1 * math.cos(a)
    local sy2 = cy + r1 * math.sin(a)
    local sx12 = cx + r2 * math.cos(a)
    local sy12 = cy + r2 * math.sin(a)
    local sx22 = cx + r3 * math.cos(a)
    local sy22 = cy + r3 * math.sin(a)
    a = 225 * deg2rad
    local sx3 = cx + r1 * math.cos(a)
    local sy3 = cy + r1 * math.sin(a)
    local sx13 = cx + r2 * math.cos(a)
    local sy13 = cy + r2 * math.sin(a)
    local sx23 = cx + r3 * math.cos(a)
    local sy23 = cy + r3 * math.sin(a)
    a = 315 * deg2rad
    local sx4 = cx + r1 * math.cos(a)
    local sy4 = cy + r1 * math.sin(a)
    local sx14 = cx + r2 * math.cos(a)
    local sy14 = cy + r2 * math.sin(a)
    local sx24 = cx + r3 * math.cos(a)
    local sy24 = cy + r3 * math.sin(a)

    local c4 = 1
    local k = r1 / rMax
    color[4] = c4 * k
    --if self.vvSign < 0 then color[4] = k - 0.3 end
    setNextStrokeColor(l2, color[1], color[2], color[3], color[4])
    addLine(l2, sx1, sy1, sx2, sy2)

    setNextStrokeColor(l2, color[1], color[2], color[3], color[4])
    addLine(l2, sx2, sy2, sx3, sy3)

    setNextStrokeColor(l2, color[1], color[2], color[3], color[4])
    addLine(l2, sx3, sy3, sx4, sy4)

    setNextStrokeColor(l2, color[1], color[2], color[3], color[4])
    addLine(l2, sx4, sy4, sx1, sy1)


    k = r2 / rMax
    color[4] = c4 * k
    --if self.vvSign < 0 then color[4] = k - 0.3 end
    setNextStrokeColor(l2, color[1], color[2], color[3], color[4])
    addLine(l2, sx11, sy11, sx12, sy12)

    setNextStrokeColor(l2, color[1], color[2], color[3], color[4])
    addLine(l2, sx12, sy12, sx13, sy13)

    setNextStrokeColor(l2, color[1], color[2], color[3], color[4])
    addLine(l2, sx13, sy13, sx14, sy14)

    setNextStrokeColor(l2, color[1], color[2], color[3], color[4])
    addLine(l2, sx14, sy14, sx11, sy11)


    k = r3 / rMax
    color[4] = c4 * k
    setNextStrokeColor(l2, color[1], color[2], color[3], color[4])
    addLine(l2, sx21, sy21, sx22, sy22)

    setNextStrokeColor(l2, color[1], color[2], color[3], color[4])
    addLine(l2, sx22, sy22, sx23, sy23)

    setNextStrokeColor(l2, color[1], color[2], color[3], color[4])
    addLine(l2, sx23, sy23, sx24, sy24)

    setNextStrokeColor(l2, color[1], color[2], color[3], color[4])
    addLine(l2, sx24, sy24, sx21, sy21)

    -- elevator
    if data.cVx ~= nil and data.cVy ~= nil then
        local spx, spy = cx-w/20, cy-h/20
        local spw, sph = w / 10, h / 10

        spx = spx + data.cVx
        spy = spy - data.cVy

        local spxMax = cx + w / 2 - w / 10
        local spxMin = cx - w / 2
        local spyMax = cy + h / 2 - h / 10
        local spyMin = cy - h / 2
        if spx > spxMax then spx = spxMax end
        if spx < spxMin then spx = spxMin end
        if spy > spyMax then spy = spyMax end
        if spy < spyMin then spy = spyMin end

        setNextStrokeColor(l3, 1, 38/255, 6/255, 1)
        addLine(l3, spx, spy, spx + spw, spy)
        setNextStrokeColor(l3, 1, 38/255, 6/255, 1)
        addLine(l3, spx, spy + sph, spx + spw, spy + sph)
        setNextStrokeColor(l3, 1, 38/255, 6/255, 1)
        addLine(l3, spx, spy, spx, spy + sph)
        setNextStrokeColor(l3, 1, 38/255, 6/255, 1)
        addLine(l3, spx + spw, spy, spx + spw, spy + sph)
        setNextFillColor(l3, 1, 38/255, 6/255, 1)
        addBox(l3, spx + 1, spy + 1, spw - 2, sph - 2)

        -- aim lines
        setNextStrokeColor(l2, 0.8, 38/255, 6/255, 0.4)
        addLine(l2, spx + w / 20, y + 2, spx + w / 20, y + h - 2)
        setNextStrokeColor(l2, 0.8, 38/255, 6/255, 0.4)
        addLine(l2, x + 2, spy + h / 20, x + w - 2, spy + h / 20)

        if data.cV > 0.2 then
            -- corr arrow
            local corVec = vec3(data.cVx, data.cVy)
            local acx = spx + w / 20 - corVec:normalize().x * w / 8
            local acy = spy + h / 20 + corVec:normalize().y * h / 8
            local rwVec = corVec:normalize()
            local lwVec = corVec:normalize()

            rwVec = rwVec:rotate(-130 * deg2rad, vec3(0,0,1)) * w / 20
            lwVec = lwVec:rotate(130 * deg2rad, vec3(0,0,1)) * w / 20

            setNextStrokeColor(l3, 1, 1, 1, 1)
            addLine(l3, acx, acy, acx - rwVec.x, acy + rwVec.y)
            addLine(l3, acx, acy, acx - lwVec.x, acy + lwVec.y)
        end
    end
end

function UI.drawHint(self, x, y, hint)
    local hw, hh = getTextBounds(self.f_xxs, hint)
    local hp = 10
    local sx = 10
    local sy = 80
    hw = hw + hp * 2
    hh = hh + hp * 2

    local hColor = {1, 33 / 255, 6/255, 0.5}
    local hfColor = {hColor[1] / 4, hColor[2] / 4, hColor[3] / 4, 0.6}
    setNextStrokeColor(hintLayer, hfColor[1], hfColor[2], hfColor[3], hfColor[4])
    addLine(hintLayer, x + sx - 1, y - sy / 2 - 1, x + sx - 1 + hw + 2, y - sy / 2 - 1)
    setNextStrokeColor(hintLayer, hfColor[1], hfColor[2], hfColor[3], hfColor[4])
    addLine(hintLayer, x + sx - 1, y - sy / 2 - 1 + hh + 2, x + sx - 1 + hw + 2, y - sy / 2 - 1 + hh + 2)
    setNextStrokeColor(hintLayer, hfColor[1], hfColor[2], hfColor[3], hfColor[4])
    addLine(hintLayer, x + sx - 1, y - sy / 2 - 1, x + sx - 1, y - sy / 2 - 1 + hh + 2)
    setNextStrokeColor(hintLayer, hfColor[1], hfColor[2], hfColor[3], hfColor[4])
    addLine(hintLayer, x + sx - 1 + hw + 2, y - sy / 2 - 1, x + sx - 1 + hw + 2, y - sy / 2 - 1 + hh + 2)

    setNextFillColor(hintLayer, 0.1, 0.01, 0.01, 0.9)
    addBox(hintLayer, x + sx, y - sy / 2, hw, hh)
    setNextTextAlign(hintLayer, AlignH_Left, AlignV_Top)
    setNextFillColor(hintLayer, hColor[1], hColor[2], hColor[3], hColor[4])
    addText(hintLayer, font_xxs, hint, x + sx + hp, y - sy / 2 + hp)
end

function UI.drawStatPanel(self, data, x , y, cx , cy)
    local lh = 40
    local tab = 50
    local bw = 30
    -- TF
    setNextTextAlign(self.layer3, AlignH_Left, AlignV_Top)
    setNextFillColor(self.layer3, 1, 33 / 255, 6 / 255, 1)
    addText(self.layer3, self.f_xs, "TF", x, y)
    setNextTextAlign(self.layer3, AlignH_Left, AlignV_Top)
    setNextFillColor(self.layer3, 1, 33 / 255, 6 / 255, 1)
    local t = "NA"
    if self.targetFloor ~= 0 then
        t = string.format("#%d", self.targetFloor)
    end
    addText(self.layer3, self.f_xs, t, x + tab, y)
    if cx >= x
    and cx <= x + bw
    and cy >= y
    and cy <= y + lh then
        self:drawHint(cx, cy, "Target Floor")
    end
    -- TA
    setNextTextAlign(self.layer3, AlignH_Left, AlignV_Top)
    setNextFillColor(self.layer3, 1, 33 / 255, 6 / 255, 1)
    addText(self.layer3, self.f_xs, "TA", x, y + lh)
    setNextTextAlign(self.layer3, AlignH_Left, AlignV_Top)
    setNextFillColor(self.layer3, 1, 33 / 255, 6 / 255, 1)
    addText(self.layer3, self.f_xs, string.format("%.2f m", self.targetAltitude), x + tab, y + lh)
    if cx >= x
    and cx <= x + bw
    and cy >= y + lh
    and cy <= y + lh * 2 then
        self:drawHint(cx, cy, "Target Altitude")
    end
    -- BD
    setNextTextAlign(self.layer3, AlignH_Left, AlignV_Top)
    setNextFillColor(self.layer3, 1, 33 / 255, 6 / 255, 1)
    addText(self.layer3, self.f_xs, "BD", x, y + lh * 2)
    setNextTextAlign(self.layer3, AlignH_Left, AlignV_Top)
    setNextFillColor(self.layer3, 1, 33 / 255, 6 / 255, 1)
    addText(self.layer3, self.f_xs, string.format("%.2f m", data.bd), x + tab, y + lh * 2)
    if cx >= x
    and cx <= x + bw
    and cy >= y + lh * 2
    and cy <= y + lh * 3 then
        self:drawHint(cx, cy, "Brake Distance")
    end
    -- TTB
    setNextTextAlign(self.layer3, AlignH_Left, AlignV_Top)
    setNextFillColor(self.layer3, 1, 33 / 255, 6 / 255, 1)
    addText(self.layer3, self.f_xs, "BT", x, y + lh * 3)
    setNextTextAlign(self.layer3, AlignH_Left, AlignV_Top)
    setNextFillColor(self.layer3, 1, 33 / 255, 6 / 255, 1)
    addText(self.layer3, self.f_xs, data.ttb, x + tab, y + lh * 3)
    if cx >= x
    and cx <= x + bw
    and cy >= y + lh * 3
    and cy <= y + lh * 4 then
        self:drawHint(cx, cy, "Brake Time")
    end
end

function UI.loop(self)
    self.t = getTime()
    self.dt = math.max(self.t - self.lt, 0.0001)
    self.lt = self.t

    self.frame = self.frame + 1
    if self.frame >= 25 then
        self.frame = 0
    end
    -- update
    local data = getData()
    self:initFloors(data, 340, sh - 67, 50, 10)

    -- reset states
    self.EBbtn.hover = false
    --self.EBbtn:setState(false)

    self:resetNumboardState()
    self:resetFloors(data)

    self:updateNumboard()
    self:updateFloors(data)

    -- DRAW ----------------------------------------------------------
    -- BG
    local bg = loadImage("assets.prod.novaquark.com/64852/94fbb171-bb60-41ce-839c-67e97faceecc.png")
    local bg2 = loadImage("assets.prod.novaquark.com/64852/59c19bf1-6233-46fe-a040-642c06c38b5b.png")
    addImage(self.layer, bg, 0, 0, sw, sh)
    local cx, cy = getCursor()
    local crl = 200
    if cx >= 0 and cy >= 0 then
        addImage(layer4, bg2, 0, 0, sw, sh)
        setLayerClipRect(layer4, cx - crl/2, cy - crl/2, crl, crl)
    end

    if self.EBbtn:inBounds(cx, cy) then
        self.EBbtn.hover = true
        if getCursorReleased() then
            self.EBbtn:toggle()
        end
    end

    setDefaultTextAlign(self.layer2, AlignH_Center, AlignV_Middle)
    if data.alt ~= nil then
        --self:drawFuelBars(self.layer2, self.f_xxs, data.atmoFuel, data.spaceFuel, self.sw / 2 + 310, self.sh / 2 + 58, 100, 14, 20)
        self:drawVelocityBars(data, self.sw / 2 + 170, self.sh /2 + 78, 30, 154)
        self:drawStatPanel(data, self.sw / 2 + 310, self.sh / 2 + 83, cx, cy)

        -- version
        setDefaultFillColor(self.layer3, Shape_Text, 1, 1, 1, 0.3)
        setDefaultTextAlign(self.layer3, AlignH_Right, AlignV_Bottom)
        addText(self.layer3, self.f_xxs, string.format("v%s", data.version), self.sw - 20, self.sh - 18)

        setNextFillColor(self.layer2, 1, 33 / 255, 6 / 255, 1)
        addBoxRounded(self.layer2, 180 - 113, self.sh / 2 - 50, 230, 40, 4)
        setNextFillColor(self.layer2, 0, 0, 0, 1)
        addBoxRounded(self.layer2, 180 - 113 + 1, self.sh / 2 - 50 + 1, 228, 38, 4)
        setNextFillColor(self.layer2, 1, 33 / 255, 6 / 255, 0.05)
        addBoxRounded(self.layer2, 180 - 113, self.sh / 2 - 50, 230, 40, 4)

        if self.tempAlt ~= "" then
            setNextFillColor(self.layer2, 1, 33 / 255, 6 / 255, 1)
            setNextTextAlign(self.layer2, AlignH_Center, AlignV_Middle)
            addText(self.layer2, self.f_xs, string.format("%s", self.tempAlt), 180, self.sh / 2 - 30)
        else
            setNextFillColor(self.layer2, 1, 33 / 255, 6 / 255, 1)
            setNextTextAlign(self.layer2, AlignH_Center, AlignV_Middle)
            addText(self.layer2, self.f_xs, string.format("%.3f", data.dAlt), 180, self.sh / 2 - 30)
        end
    end

    -- axis visualizing
    self:drawAxis(data)

    -- deviation
    self:drawDeviation(data, self.sw / 2 + 170, 57 + 20, 270, 270)

    -- buttons
    self.EBbtn:draw()
    self:drawNumboard()

    self:drawFloors(data)

    local len = self.tempAlt:len()

    for i = 0, 9 do
        if self["btn" .. i]:getState() then
            self.tempAlt = self.tempAlt .. i
        end
    end

    if self.btnSign:getState() then
        if len > 0 then
            self.tempAlt = tostring(-tonumber(self.tempAlt))
        end
    end
    if self.btnDec:getState() then
        self.tempAlt = self.tempAlt .. "."
    end

    if self.btnCancel:getState() then
        self.tempAlt = ""
    end

    if self.btnBack:getState() and self.tempAlt ~= "" then
        if len > 1 then
            self.tempAlt = self.tempAlt:sub(1, len - 1)
        else
            self.tempAlt = "0"
        end
    end

    -- prepare data for unit
    local bAlt = data.alt
    local flrs = data.fl
    data = {}

    if self.btnAccept:getState() and self.tempAlt ~= "" then
        data.dAlt = self.tempAlt
        self.targetFloor = 0
        self.targetAltitude = data.dAlt
        self.tempAlt = ""
    end
    if self.addFloorBtn:getState() then
        data.newFloor = bAlt
        self.floorsLoaded = false
    end

    for i, e in pairs(flrs) do
        if self["floor"..i]:getState() then
            data.dAlt = self["floor"..i].value
            self.targetFloor = i
            self.targetAltitude = data.dAlt
        end
        if i > 1 then
            if self["rfloor"..i]:getState() then
                data.rfloor = self["rfloor"..i].value
                self.floorsLoaded = false
            end
        end
    end

    if self.EBbtn:getState() then
        data.EB = 1
    end

    sendData(data)
end

layer = createLayer()
layer4 = createLayer()
layer5 = createLayer()
layer2 = createLayer()
layer3 = createLayer()
hintLayer = createLayer()
sw, sh = getResolution()
baseFontSize = math.floor(sh / 20)
baseThick = math.floor(sh / 204.3)
font_xxs = loadFont("RobotoCondensed", baseFontSize - 14)
font_xs = loadFont("RobotoCondensed", baseFontSize - 6)
font_s = loadFont("RobotoCondensed", baseFontSize + 4)
font_m = loadFont("RobotoMono-Bold", baseFontSize + 6)

if not init then
    init = true
    ui = UI.new(layer, layer2, layer3, font_xxs, font_xs, font_s, font_m, baseThick, sw, sh)
end

-- main loop
ui:loop()

requestAnimationFrame(2)