-- ANSI terminal control

local M = {}

local prefix = '\27['

M.home            = prefix .. 'H'
M.clear_to_bottom = prefix .. 'J'
M.clear_screen    = prefix .. '2J' .. M.home
M.clear_to_eol    = prefix .. 'K'

M.save_cursor_pos    = prefix .. 's'
M.restore_cursor_pos = prefix .. 'u'

M.show_cursor = prefix .. '?25h'
M.hide_cursor = prefix .. '?25l'

function M.goto(x, y)
   return prefix .. ('%d;%dH'):format(y+1, x+1)
end

M.black   = 0
M.red     = 1
M.green   = 2
M.yellow  = 3
M.blue    = 4
M.magenta = 5
M.cyan    = 6
M.white   = 7

function M.bright(color)
   return 60 + color
end

function M.set_foreground(color)
   return prefix .. ('%dm'):format(30 + color)
end

function M.set_background(color)
   return prefix .. ('%dm'):format(40 + color)
end

return M
