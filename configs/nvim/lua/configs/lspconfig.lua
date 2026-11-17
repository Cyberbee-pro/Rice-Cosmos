require("nvchad.configs.lspconfig").defaults()

local servers = { 
  "html", 
  "cssls",
  "clangd",  -- C / C++
  "jdtls",   -- Java
  "ts_ls",   -- TypeScript
  "nil_ls",  -- Nix expression language
  "asm_lsp",  -- x86-64 Assembly
  "bashls"
}
vim.lsp.enable(servers)

-- read :h vim.lsp.config for changing options of lsp servers 
