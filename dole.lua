require('ansi_term')

local rows, cols = io.popen('stty size'):read():match('(%d+) (%d+)')
screen_rows, screen_cols = 0+rows, 0+cols

function main()
   os.execute('stty raw -echo')
   pcall(function ()
            io.write(clear_screen)
            reacting()
         end)
   os.execute('stty sane')
end

function reacting()
   io.write('Welcome to dole\r\n')
   io.write(io.read(1))
end

main()
io.write('\n')
