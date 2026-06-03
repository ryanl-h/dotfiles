require("nvchad.configs.lspconfig").defaults()

-- We replaced nvim-cmp with blink.cmp; give every server blink's capabilities.
local ok, blink = pcall(require, "blink.cmp")
if ok then
  vim.lsp.config("*", { capabilities = blink.get_lsp_capabilities() })
end

-- Servers to enable. Mason installs them via plugins/tooling.lua.
local servers = {
  "lua_ls",
  "basedpyright", -- types/hover (maintained pyright fork)
  "ruff",         -- python lint/format/imports (built-in `ruff server`; ruff-lsp is dead)
  "ts_ls",        -- renamed from tsserver
  "eslint",       -- JS/TS lint via LSP (only attaches with an eslint config)
  "html",
  "cssls",
  "jsonls",
  "tailwindcss",
  "yamlls",
  "bashls",
  "dockerls",
  "marksman",
  "taplo",
}

-- Python: basedpyright owns types/hover; ruff owns lint/format/imports.
vim.lsp.config("basedpyright", {
  settings = {
    basedpyright = {
      analysis = {
        autoSearchPaths = true,
        useLibraryCodeForTypes = true,
        diagnosticMode = "openFilesOnly",
      },
      disableOrganizeImports = true, -- ruff organizes imports instead
    },
  },
})

-- JSON: validate against the SchemaStore catalog.
vim.lsp.config("jsonls", {
  settings = {
    json = {
      schemas = require("schemastore").json.schemas(),
      validate = { enable = true },
    },
  },
})

-- YAML: disable yamlls' built-in store, use SchemaStore.nvim, and map the
-- bundled Kubernetes schema onto our manifest globs.
local yaml_schemas = require("schemastore").yaml.schemas()
yaml_schemas["kubernetes"] = { "k8s/**/*.yaml", "*.k8s.yaml", "kustomization.yaml" }
vim.lsp.config("yamlls", {
  settings = {
    yaml = {
      schemaStore = { enable = false, url = "" },
      schemas = yaml_schemas,
      keyOrdering = false, -- k8s manifests aren't alphabetical
    },
  },
})

vim.lsp.enable(servers)

-- ruff's hover duplicates basedpyright's; let basedpyright own it.
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("ruff_no_hover", { clear = true }),
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client and client.name == "ruff" then
      client.server_capabilities.hoverProvider = false
    end
  end,
})
