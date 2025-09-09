qrencode = dofile("./luaqrcode/qrencode.lua")

-- This script requires UI
if not app.isUIAvailable then
    return
end

function init(plugin)
    plugin:newCommand{
        id = "qr_code_gen",
        title = "Generate QR-Code",
        group = "file_recent",
        onclick = function()
            local c_white
            local c_black

            local spr = app.activeSprite
            if spr then
                local fg = app.fgColor
                local bg = app.bgColor

                c_white = Color {
                    r = fg.red,
                    g = fg.green,
                    b = fg.blue,
                    a = fg.alpha
                }
                c_black = Color {
                    r = bg.red,
                    g = bg.green,
                    b = bg.blue,
                    a = bg.alpha
                }
            else
                c_white = Color {
                    r = 255,
                    g = 255,
                    b = 255,
                    a = 255
                }
                c_black = Color {
                    r = 0,
                    g = 0,
                    b = 0,
                    a = 255
                }
            end

            local dialog = Dialog("QR-Code Generator")
            dialog:entry{
                id = "input",
                label = "Text",
                text = ""
            }
            dialog:separator{
                id = "separator",
                text = "Colors"
            }
            dialog:color{
                id = "color_black",
                label = "QR Color",
                color = c_black
            }
            dialog:color{
                id = "color_white",
                label = "Background",
                color = c_white
            }

            dialog:button{
                id = "confirm",
                text = "Confirm",
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

            dialog:show{
                wait = false
            }
        end
    }
end

function generate_qr_code(dialog)
    local input = dialog.data.input
    c_white = dialog.data.color_white
    c_black = dialog.data.color_black

    local ok, tab_or_message = qrencode.qrcode(input)
    if not ok then
        print(tab_or_message)
    end

    local sprite = Sprite(#tab_or_message + 2, #tab_or_message[1] + 2)
    local pal = Palette(2)
    pal:setColor(0, c_white)
    pal:setColor(1, c_black)
    sprite:setPalette(pal)

    local img = app.image

    for it in img:pixels() do
        img:drawPixel(it.x, it.y, c_white)
    end

    for x = 1, #tab_or_message do
        for y = 1, #tab_or_message[1] do
            if tab_or_message[x][y] < 0 then
                img:drawPixel(x, y, c_white)
            elseif tab_or_message[x][y] > 0 then
                img:drawPixel(x, y, c_black)
            end
        end
    end

    dialog:close()
end
