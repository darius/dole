-- ANSI terminal control

local prefix = '\27['

home            = prefix .. 'H'
clear_to_bottom = prefix .. 'J'
clear_screen    = prefix .. '2J' .. home
clear_to_eol    = prefix .. 'K'

save_cursor_pos = prefix .. 's'
restore_cursor_pos = prefix .. 'u'

show_cursor = prefix .. '?25h'
hide_cursor = prefix .. '?25l'

function goto(x, y)
   return prefix .. ('%d;%dH'):format(y+1, x+1)
end

black, red, green, yellow, blue, magenta, cyan, white = 0,1,2,3,4,5,6,7

function bright(color)
   return 60 + color
end

function set_foreground(color)
   return prefix .. ('%dm'):format(30 + color)
end

function set_background(color)
   return prefix .. ('%dm'):format(40 + color)
end
