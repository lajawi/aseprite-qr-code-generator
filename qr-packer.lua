local Qrencode = dofile("./luaqrcode/qrencode.lua")

if not app.isUIAvailable then
    return
end

local pluginName = ""
local qrTable = {}

local ERROR_CORRECTION_LEVELS = {
    { id = "ec_l", text = "Low" },
    { id = "ec_m", text = "Medium" },
    { id = "ec_q", text = "Quartile" },
    { id = "ec_h", text = "High" }
}

local function absolutePath(file)
    local path = app.fs.joinPath(app.fs.userConfigPath, "extensions", pluginName, file)
    return path
end

local function readTextFle(file)
    local lines = {}
    for line in io.lines(file) do
        table.insert(lines, line)
    end
    return lines
end

local function readRelativeTextFile(file)
    return readTextFle(absolutePath(file))
end

local function readLicense(dialog, file)
    local dlg = Dialog{ title = "License", parent = dialog}
    :newrow{ always = true }
    local license = readRelativeTextFile(file)
    for i = 1, #license do
        dlg:label{ text = license[i] }
    end
    dlg:show{ wait = true, autoscrollbars = true }
end

--#region Licenses Dialog
local licensesDialog = Dialog("QR-Code Generator Licenses")
licensesDialog:separator{ text = "Luaqrcode License" }
:label{ text = "All files in ./luaqrcode are subject to this license." }
:button{ text = "Open Luaqrcode License",
    onclick = function()
        readLicense(licensesDialog, "luaqrcode/License.md")
    end
}
:separator{ text = "Lajawi Aseprite QR-Code Generator License" }
:label{ text = "All files in the extension besides the ones in ./luaqrcode are subject to this license." }
:button { text = "Open License",
    onclick = function()
        readLicense(licensesDialog, "LICENSE")
    end
}
:label{ text = "The full extension, including author and contributors can be found on GitHub." }
:newrow()
:label{ text = "https://github.com/lajawi/aseprite-qr-code-generator/" }
--#endregion

local mainDialog = Dialog("QR-Code Generator")

local colorBg
local colorQr

local function setQrTable()
    local input = mainDialog.data.input
    local useAdvancedOptions = mainDialog.data.adv_options
    local errorCorrectionLevel = 4
    for i,ec in ipairs(ERROR_CORRECTION_LEVELS) do
        if mainDialog.data[ec.id] then
            errorCorrectionLevel = i
        end
    end

    local ok, tableOrMessage
    if useAdvancedOptions then
        ok, tableOrMessage = Qrencode.qrcode(input, errorCorrectionLevel)
    else
        ok, tableOrMessage = Qrencode.qrcode(input)
    end

    if not ok then
        print(tableOrMessage)
        return
    end

    qrTable = tableOrMessage
end

local function initColors()
    local spr = app.activeSprite
    if spr then
        local fg = app.fgColor
        local bg = app.bgColor

        colorBg = Color{ r = bg.red, g = bg.green, b = bg.blue, a = bg.alpha }
        colorQr = Color{ r = fg.red, g = fg.green, b = fg.blue, a = fg.alpha }
    else
        colorBg = Color{ r = 255, g = 255, b = 255, a = 255 }
        colorQr = Color{ r = 0, g = 0, b = 0, a = 255 }
    end

    mainDialog:modify{ id = "color_bg", color = colorBg }
    :modify{ id = "color_qr", color = colorQr }
end

---@return Image
local function getQrCodeImage()
    setQrTable()

    local image = Image(#qrTable + 2, #qrTable + 2)
    for x = 1, #qrTable do
        for y = 1, #qrTable[1] do
            if qrTable[x][y] > 0 then
                image:drawPixel(x, y, colorQr)
            end
        end
    end
    return image
end

local function createSprite()
    setQrTable()

    colorBg = mainDialog.data.color_bg
    colorQr = mainDialog.data.color_qr

    local sprite = Sprite(#qrTable + 2, #qrTable[1] + 2)
    local pal = Palette(2)
    pal:setColor(0, colorBg)
    pal:setColor(1, colorQr)
    sprite:setPalette(pal)
    sprite.layers[1].name = "Background"

    app.bgColor = colorBg
    app.command.BackgroundFromLayer()

    local layer = sprite:newLayer()
    layer.name = "QR-Code"
    sprite:newCel(layer, 1, getQrCodeImage(), Point(0, 0))

    mainDialog:close()
end

local function toggleUseAdvancedOptions()
    local vis = mainDialog.data.adv_options
    mainDialog:modify{ id = "ec_label", visible = vis }
    for _,ec in ipairs(ERROR_CORRECTION_LEVELS) do
        mainDialog:modify{ id = ec.id, visible = vis }
    end
end

--#region Main Dialog
mainDialog:separator{ text = "Data:" }
:entry{ id = "input", text = "https://example.com", focus = true }
:separator{ text = "Colors:" }
:color{ id = "color_qr", color = colorQr }
:color{ id = "color_bg", color = colorBg }
:check{ id = "adv_options", text = "Use Advanced Options", onclick = toggleUseAdvancedOptions }
:separator{ id = "ec_label", text = "Error Correction Level:", visible = false }
:newrow{ always = true }
for _,ec in ipairs(ERROR_CORRECTION_LEVELS) do
    mainDialog:radio{ id = ec.id, visible = false, text = ec.text }
end
mainDialog:modify{ id = ERROR_CORRECTION_LEVELS[#ERROR_CORRECTION_LEVELS].id, selected = true }
:newrow{ always = false }
:button{ id = "confirm", text = "OK", focus = true, onclick = createSprite }
:button{ id = "cancel", text = "Cancel" }
:separator{ id = "licenses", text = "Licenses:" }
:button{ id = "licenses_button", text = "Open Licenses",
    onclick = function()
        mainDialog:close()
        licensesDialog:show{ wait = false }
    end
}
--#endregion

function init(plugin)
    pluginName = plugin.name

    plugin:newCommand{
        id = "qr_code_gen",
        title = "Generate QR-Code",
        group = "file_recent",
        onclick = function()
            initColors()
            mainDialog:show{ wait = true }
        end
    }
end
