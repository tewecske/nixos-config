-- Wrapper so `:colorscheme circadia-light` works: circadia's Neovim port ships no
-- colors/ dir of its own. The module is on the runtimepath via the rtp prepend
-- in init.lua. setup() also sets colors_name, termguicolors and background.
vim.o.background = 'light'
require('circadia').setup { mode = 'light' }
