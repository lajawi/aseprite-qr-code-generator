qrencode = dofile("./luaqrcode/qrencode.lua")

-- This script requires UI
if not app.isUIAvailable then
    return
end

local ec_low = {
    id = "ec_l",
    text = "Low",
}
local ec_medium = {
    id = "ec_m",
    text = "Medium",
}
local ec_quartile = {
    id = "ec_q",
    text = "Quartile",
}
local ec_high = {
    id = "ec_h",
    text = "High",
}

local ec_levels = {
    ec_low,
    ec_medium,
    ec_quartile,
    ec_high
}

function init(plugin)
    plugin:newCommand{
        id = "qr_code_gen",
        title = "Generate QR-Code",
        group = "file_recent",
        onclick = function()
            local c_bg
            local c_qr

            local spr = app.activeSprite
            if spr then
                local fg = app.fgColor
                local bg = app.bgColor

                c_bg = Color {
                    r = bg.red,
                    g = bg.green,
                    b = bg.blue,
                    a = bg.alpha
                }
                c_qr = Color {
                    r = fg.red,
                    g = fg.green,
                    b = fg.blue,
                    a = fg.alpha
                }
            else
                c_bg = Color {
                    r = 255,
                    g = 255,
                    b = 255,
                    a = 255
                }
                c_qr = Color {
                    r = 0,
                    g = 0,
                    b = 0,
                    a = 255
                }
            end

            local dialog = Dialog("QR-Code Generator")
            dialog:separator{
                text = "Data:",
            }
            dialog:entry{
                id = "input",
                text = "https://example.com",
                focus = true
            }
            dialog:separator{
                text = "Colors:"
            }
            dialog:color{
                id = "color_qr",
                color = c_qr
            }
            dialog:color{
                id = "color_bg",
                color = c_bg
            }
            dialog:check{
                id = "adv_options",
                text = "Use Advanced Options",
                onclick = function()
                    local vis = dialog.data.adv_options
                    dialog:modify{
                        id = "ec_label",
                        visible = vis,
                    }
                    for _,ec in ipairs(ec_levels) do
                        dialog:modify{
                            id = ec.id,
                            visible = vis,
                        }
                    end
                end
            }
            dialog:separator{
                id = "ec_label",
                text = "Error Correction Level:",
                visible = false,
            }

            dialog:newrow{ always = true }
            for _,ec in ipairs(ec_levels) do
                dialog:radio{
                    id = ec.id,
                    visible = false,
                    text = ec.text,
                }
            end
            dialog:modify{
                id = ec_levels[#ec_levels].id,
                selected = true,
            }
            dialog:newrow{ always = false }

            dialog:button{
                id = "confirm",
                text = "OK",
                focus = true,
                onclick = function()
                    generate_qr_code(dialog)
                end
            }
            dialog:button{
                id = "cancel",
                text = "Cancel",
                onclick = function()
                    dialog:close()
                end
            }

            dialog:separator{
                id = "licenses",
                text = "Licenses:"
            }
            dialog:button{
                id = "licenses_button",
                text = "Open Licenses",
                onclick = function()
                    dialog:close()
                    show_licenses()
                end
            }

            dialog:show{
                wait = true
            }
        end
    }
end

function generate_qr_code(dialog)
    local input = dialog.data.input
    local c_bg = dialog.data.color_bg
    local c_qr = dialog.data.color_qr
    local use_adv_opts = dialog.data.adv_options
    local ec_level = 4

    for i,ec in ipairs(ec_levels) do
        if dialog.data[ec.id] then
            ec_level = i
        end
    end

    local ok, tab_or_message
    if use_adv_opts then
        ok, tab_or_message = qrencode.qrcode(input, ec_level)
    else
        ok, tab_or_message = qrencode.qrcode(input)
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

    dialog:close()
end

function show_licenses()
    local dialog = Dialog("QR-Code Generator Licenses")
    dialog:separator{
        text = "Luaqrcode License"
    }
    dialog:label{
        text = "All files in ./luaqrcode are subject to this license."
    }
    dialog:button{
        text = "Open Luaqrcode License",
        onclick = function()
            read_license(dialog, "luaqrcode/License.md")
        end
    }

    dialog:separator{
        text = "Lajawi Aseprite QR-Code Generator License"
    }
    dialog:label{
        text = "All files in the extension besides the ones in ./luaqrcode are subject to this license."
    }
    dialog:button {
        text = "Open License",
        onclick = function()
            read_license(dialog, "LICENSE")
        end
    }
    dialog:label{
        text = "The full extension, including author and contributors can be found on GitHub."
    }
    dialog:newrow()
    dialog:label{
        text = "https://github.com/lajawi/aseprite-qr-code-generator/"
    }

    dialog:show{
        wait = false
    }
end

function absolute_path(file)
    local path = app.fs.joinPath(app.fs.userConfigPath, "extensions", "lajawi-qr-code-gen", file)
    return path
end

function read_text_file(file)
    local lines = {}
    for line in io.lines(file) do
        table.insert(lines, line)
    end
    return lines
end

function read_relative_text_file(file)
    return read_text_file(absolute_path(file))
end

function read_license(dialog, file)
    local lic_dialog = Dialog{
        title = "License",
        parent = dialog
    }:newrow{ always = true }

    local license = read_relative_text_file(file)
    for i = 1, #license do
        lic_dialog:label{
            text = license[i]
        }
    end

    lic_dialog:show{
        wait = true,
        autoscrollbars = true
    }
end
