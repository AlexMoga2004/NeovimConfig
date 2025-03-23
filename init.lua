vim.wo.number = true
vim.api.nvim_set_keymap("i", "<A-BS>", "<C-w>", { noremap = true, silent = true })

vim.cmd("set expandtab")
vim.cmd("set tabstop=4")
vim.cmd("set softtabstop=4")
vim.cmd("set shiftwidth=4")
vim.cmd("vnoremap < <gv")
vim.cmd("vnoremap > >gv")

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	local lazyrepo = "https://github.com/folke/lazy.nvim.git"
	local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
	if vim.v.shell_error ~= 0 then
		vim.api.nvim_echo({
			{ "Failed to clone lazy.nvim:\n", "ErrorMsg" },
			{ out, "WarningMsg" },
			{ "\nPress any key to exit..." },
		}, true, {})
		vim.fn.getchar()
		os.exit(1)
	end
end
vim.opt.rtp:prepend(lazypath)

-- Make sure to setup `mapleader` and `maplocalleader` before
-- loading lazy.nvim so that mappings are correct.
-- This is also a good place to setup other settings (vim.opt)
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Setup lazy.nvim
require("lazy").setup({
	spec = {
		-- Cyberdream theme
		{
			"scottmckendry/cyberdream.nvim",
			lazy = false,
			priority = 1000,
			config = function()
				require("cyberdream").setup({
					transparent = true, -- Enable transparency
					theme = {
						variant = "default",
						saturation = 1,
					},
				})
				-- Uncomment to make this the default theme:
				vim.cmd.colorscheme("cyberdream")
			end,
		},

		{
			"nvim-telescope/telescope.nvim",
			tag = "0.1.8",
			-- or                              , branch = '0.1.x',
			dependencies = { "nvim-lua/plenary.nvim" },
		},
		{
			"nvim-treesitter/nvim-treesitter",
			build = ":TSUpdate",
			config = function()
				require("neo-tree").setup({
					close_if_last_window = true,
				})
				require("nvim-treesitter.configs").setup({
					-- Specify the languages you want to support
					ensure_installed = { "lua", "javascript", "python", "html", "css", "cpp" }, -- Add more as needed

					-- Enable syntax highlighting
					highlight = {
						enable = true, -- Enable Tree-sitter-based highlighting
						additional_vim_regex_highlighting = false, -- Disable Vim regex-based highlighting
					},

					-- Enable indenting
					indent = {
						enable = true, -- Enable Tree-sitter-based indenting
					},

					-- Optional: Enable incremental selection
					incremental_selection = {
						enable = true,
						keymaps = {
							init_selection = "gnn",
							node_incremental = "grn",
							scope_incremental = "grc",
							node_decremental = "grm",
						},
					},
				})
			end,
		},
		{
			"nvim-neo-tree/neo-tree.nvim",
			branch = "v3.x",
			init = function()
				if vim.fn.argc(-1) == 1 then
					local stat = vim.loop.fs_stat(vim.fn.argv(0))
					if stat and stat.type == "directory" then
						require("neo-tree").setup({
							filesystem = {
								hijack_netrw_behavior = "open_current",
							},
						})
					end
				end
			end,
			dependencies = {
				"nvim-lua/plenary.nvim",
				"nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
				"MunifTanjim/nui.nvim",
				-- "3rd/image.nvim", -- Optional image support in preview window: See `# Preview Mode` for more information
			},
		},
		{
			"williamboman/mason.nvim",
			config = function()
				require("mason").setup()
			end,
		},
		{
			"williamboman/mason-lspconfig.nvim",
			config = function()
				require("mason-lspconfig").setup({
					ensure_installed = { "lua_ls", "pyright", "clangd" },
				})
			end,
		},
		{
			"neovim/nvim-lspconfig",
			lazy = false,
			config = function()
				local capabilities = require("cmp_nvim_lsp").default_capabilities()
				local lspconfig = require("lspconfig")
				lspconfig.lua_ls.setup({ capabilities = capabilities })
				lspconfig.pyright.setup({ capabilities = capabilities })
				lspconfig.clangd.setup({
					capabilities = capabilities,
					on_attach = function(client)
						client.server_capabilities.documentFormattingProvider = false
					end,
				})
				vim.keymap.set("n", "K", vim.lsp.buf.hover, {})
				vim.keymap.set("n", "gd", vim.lsp.buf.definition, {})
				vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, {})
			end,
		},
		{
			"nvim-telescope/telescope-ui-select.nvim",
			config = function()
				require("telescope").setup({
					["ui-select"] = {
						require("telescope.themes").get_dropdown({}),
					},
				})
				require("telescope").load_extension("ui-select")
			end,
		},
		{
			"nvimtools/none-ls.nvim",
			config = function()
				local null_ls = require("null-ls")
				null_ls.setup({
					timeout = 10000,
					sources = {
						null_ls.builtins.formatting.stylua, -- lua
						null_ls.builtins.formatting.prettier, -- js/ts
						null_ls.builtins.formatting.isort, -- python imports
						null_ls.builtins.formatting.black.with({ -- python
							extra_args = { "--fast" },
						}),
						-- null_ls.builtins.diagnostics.eslint_d,
						null_ls.builtins.formatting.clang_format.with({
							filetypes = { "c", "h", "cpp", "objc", "objcpp" }, -- Apply to C/C++
							extra_args = { "--style={BasedOnStyle: llvm, IndentWidth: 4, SpacesInAngles: true}" },
						}),
					},
				})

				vim.keymap.set("n", "<leader>gf", vim.lsp.buf.format, {})
			end,
		},
		{
			"hrsh7th/cmp-nvim-lsp",
		},
		{
			"L3MON4D3/LuaSnip",
			dependencies = {
				"saadparwaiz1/cmp_luasnip",
				"rafamadriz/friendly-snippets",
			},
		},
		{
			"hrsh7th/nvim-cmp",
			config = function()
				local cmp = require("cmp")
				require("luasnip.loaders.from_vscode").lazy_load()

				cmp.setup({
					snippet = {
						-- REQUIRED - you must specify a snippet engine
						expand = function(args)
							-- vim.fn["vsnip#anonymous"](args.body) -- For `vsnip` users.
							require("luasnip").lsp_expand(args.body) -- For `luasnip` users.
							-- require('snippy').expand_snippet(args.body) -- For `snippy` users.
							-- vim.fn["UltiSnips#Anon"](args.body) -- For `ultisnips` users.
							-- vim.snippet.expand(args.body) -- For native neovim snippets (Neovim v0.10+)
						end,
					},
					window = {
						completion = cmp.config.window.bordered(),
						documentation = cmp.config.window.bordered(),
					},
					mapping = cmp.mapping.preset.insert({
						["<C-b>"] = cmp.mapping.scroll_docs(-4),
						["<C-f>"] = cmp.mapping.scroll_docs(4),
						["<C-Space>"] = cmp.mapping.complete(),
						["<C-e>"] = cmp.mapping.abort(),
						["<CR>"] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
						-- Use Tab to navigate through suggestions
						["<Tab>"] = cmp.mapping(function(fallback)
							if cmp.visible() then
								cmp.select_next_item()
							else
								fallback()
							end
						end, { "i", "s" }),

						-- Use Shift+Tab to navigate backward through suggestions
						["<S-Tab>"] = cmp.mapping(function(fallback)
							if cmp.visible() then
								cmp.select_prev_item()
							else
								fallback()
							end
						end, { "i", "s" }),
					}),
					sources = cmp.config.sources({
						{ name = "nvim_lsp" },
						-- { name = "vsnip" }, -- For vsnip users.
						{ name = "luasnip" }, -- For luasnip users.
						-- { name = 'ultisnips' }, -- For ultisnips users.
						-- { name = 'snippy' }, -- For snippy users.
					}, {
						{ name = "buffer" },
					}),
				})
			end,
		},
		{
			"numToStr/Comment.nvim",
		},
		{
			"windwp/nvim-autopairs",
			event = "InsertEnter",
			config = function()
				require("nvim-autopairs").setup({})
			end,
		},
	},
	-- Other lazy.nvim settings
})
vim.api.nvim_set_keymap("n", "<leader>y", ":.y+ | :q!<CR>", { noremap = true, silent = true })

vim.api.nvim_set_hl(0, "LineNr", { fg = "#ffd700", bg = "NONE" }) -- Regular line numbers
vim.api.nvim_set_hl(0, "CursorLineNr", { fg = "#ffff5f", bg = "NONE", bold = true }) -- Current line number
vim.api.nvim_set_hl(0, "Comment", { fg = "#87CEFA", italic = true })
vim.api.nvim_set_hl(0, "Visual", { bg = "#B0B0B0", fg = "None" })

local builtin = require("telescope.builtin")
vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Telescope find files" })
vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Telescope live grep" })
vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Telescope buffers" })
vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Telescope help tags" })
vim.keymap.set("n", "<leader>e", ":Neotree filesystem reveal left<CR>")
-- vim.keymap.set("n", "<leader>e", ":Neotree toggle filesystem left<CR>")

vim.cmd([[
  augroup LspFormatting
    autocmd!
    autocmd BufWritePre * lua vim.lsp.buf.format()
  augroup END
]])
