-- ANSI terminal control

local ansi_term = {}

local prefix = '\27['

ansi_term.home            = prefix .. 'H'
ansi_term.clear_to_bottom = prefix .. 'J'
ansi_term.clear_screen    = prefix .. '2J' .. ansi_term.home
ansi_term.clear_to_eol    = prefix .. 'K'

ansi_term.save_cursor_pos    = prefix .. 's'
ansi_term.restore_cursor_pos = prefix .. 'u'

ansi_term.show_cursor = prefix .. '?25h'
ansi_term.hide_cursor = prefix .. '?25l'

function ansi_term.goto(x, y)
   return prefix .. ('%d;%dH'):format(y+1, x+1)
end

-- XXX
black, red, green, yellow, blue, magenta, cyan, white = 0,1,2,3,4,5,6,7

function ansi_term.bright(color)
   return 60 + color
end

function ansi_term.set_foreground(color)
   return prefix .. ('%dm'):format(30 + color)
end

function ansi_term.set_background(color)
   return prefix .. ('%dm'):format(40 + color)
end

return ansi_term
