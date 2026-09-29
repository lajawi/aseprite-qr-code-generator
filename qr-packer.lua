local Qrencode = dofile("./luaqrcode/qrencode.lua")

if not app.isUIAvailable then
    return
end

local plugin_name = ""

local ec_levels = {
    { id = "ec_l", text = "Low" },
    { id = "ec_m", text = "Medium" },
    { id = "ec_q", text = "Quartile" },
    { id = "ec_h", text = "High" }
}

local function absolute_path(file)
    local path = app.fs.joinPath(app.fs.userConfigPath, "extensions", plugin_name, file)
    return path
end

local function read_text_file(file)
    local lines = {}
    for line in io.lines(file) do
        table.insert(lines, line)
    end
    return lines
end

local function read_relative_text_file(file)
    return read_text_file(absolute_path(file))
end

local function read_license(dialog, file)
    local lic_dialog = Dialog{ title = "License", parent = dialog}
    :newrow{ always = true }
    local license = read_relative_text_file(file)
    for i = 1, #license do
        lic_dialog:label{ text = license[i] }
    end
    lic_dialog:show{ wait = true, autoscrollbars = true }
end

--#region Licenses Dialog
local licenses_dialog = Dialog("QR-Code Generator Licenses")
licenses_dialog:separator{ text = "Luaqrcode License" }
:label{ text = "All files in ./luaqrcode are subject to this license." }
:button{ text = "Open Luaqrcode License",
    onclick = function()
        read_license(licenses_dialog, "luaqrcode/License.md")
    end
}
:separator{ text = "Lajawi Aseprite QR-Code Generator License" }
:label{ text = "All files in the extension besides the ones in ./luaqrcode are subject to this license." }
:button { text = "Open License",
    onclick = function()
        read_license(licenses_dialog, "LICENSE")
    end
}
:label{ text = "The full extension, including author and contributors can be found on GitHub." }
:newrow()
:label{ text = "https://github.com/lajawi/aseprite-qr-code-generator/" }
--#endregion

local main_dialog = Dialog("QR-Code Generator")

local color_bg
local color_qr

local function set_colors()
    local spr = app.activeSprite
    if spr then
        local fg = app.fgColor
        local bg = app.bgColor

        color_bg = Color{ r = bg.red, g = bg.green, b = bg.blue, a = bg.alpha }
        color_qr = Color{ r = fg.red, g = fg.green, b = fg.blue, a = fg.alpha }
    else
        color_bg = Color{ r = 255, g = 255, b = 255, a = 255 }
        color_qr = Color{ r = 0, g = 0, b = 0, a = 255 }
    end

    main_dialog:modify{ id = "color_bg", color = color_bg }
    :modify{ id = "color_qr", color = color_qr }
end

local function generate_qr_code()
    local input = main_dialog.data.input
    local c_bg = main_dialog.data.color_bg
    local c_qr = main_dialog.data.color_qr
    local use_adv_opts = main_dialog.data.adv_options
    local ec_level = 4

    for i,ec in ipairs(ec_levels) do
        if main_dialog.data[ec.id] then
            ec_level = i
        end
    end

    local ok, tab_or_message
    if use_adv_opts then
        ok, tab_or_message = Qrencode.qrcode(input, ec_level)
    else
        ok, tab_or_message = Qrencode.qrcode(input)
    end

    if not ok then
        print(tab_or_message)
    end

    local sprite = Sprite(#tab_or_message + 2, #tab_or_message[1] + 2)
    local pal = Palette(2)
    pal:setColor(0, c_bg)
    pal:setColor(1, c_qr)
    sprite:setPalette(pal)
    sprite.layers[1].name = "Background"

    app.bgColor = c_bg
    app.command.BackgroundFromLayer()

    local layer = sprite:newLayer()
    layer.name = "QR-Code"
    sprite:newCel(layer, 1)

    for x = 1, #tab_or_message do
        for y = 1, #tab_or_message[1] do
            if tab_or_message[x][y] > 0 then
                app.image:drawPixel(x, y, c_qr)
            end
        end
    end

    main_dialog:close()
end

local function toggle_use_advanced_options()
    local vis = main_dialog.data.adv_options
    main_dialog:modify{ id = "ec_label", visible = vis }
    for _,ec in ipairs(ec_levels) do
        main_dialog:modify{ id = ec.id, visible = vis }
    end
end

--#region Main Dialog
main_dialog:separator{ text = "Data:" }
:entry{ id = "input", text = "https://example.com", focus = true }
:separator{ text = "Colors:" }
:color{ id = "color_qr", color = color_qr }
:color{ id = "color_bg", color = color_bg }
:check{ id = "adv_options", text = "Use Advanced Options", onclick = toggle_use_advanced_options }
:separator{ id = "ec_label", text = "Error Correction Level:", visible = false }
:newrow{ always = true }
for _,ec in ipairs(ec_levels) do
    main_dialog:radio{ id = ec.id, visible = false, text = ec.text }
end
main_dialog:modify{ id = ec_levels[#ec_levels].id, selected = true }
:newrow{ always = false }
:button{ id = "confirm", text = "OK", focus = true, onclick = generate_qr_code }
:button{ id = "cancel", text = "Cancel" }
:separator{ id = "licenses", text = "Licenses:" }
:button{ id = "licenses_button", text = "Open Licenses",
    onclick = function()
        main_dialog:close()
        licenses_dialog:show{ wait = false }
    end
}
--#endregion

function init(plugin)
    plugin_name = plugin.name

    plugin:newCommand{
        id = "qr_code_gen",
        title = "Generate QR-Code",
        group = "file_recent",
        onclick = function()
            set_colors()
            main_dialog:show{ wait = true }
        end
    }
end
