-- Wrapper so `:colorscheme circadia-dark` works: circadia's Neovim port ships no
-- colors/ dir of its own. The module is on the runtimepath via the rtp prepend
-- in init.lua. setup() also sets colors_name, termguicolors and background.
vim.o.background = 'dark'
require('circadia').setup { mode = 'dark' }
