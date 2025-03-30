local home = os.getenv 'USERPROFILE'
-- 🛑 Danger 1: If USERPROFILE contains spaces or special characters
local workspace_path = home .. '\\AppData\\Local\\nvim-data\\jdtls-workspace\\'
local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ':p:h:t')
local workspace_dir = workspace_path .. project_name

-- 🛑 Danger 2: Lombok path might be incorrect
local lombok_path = home .. '\\AppData\\Local\\nvim-data\\mason\\packages\\jdtls\\lombok.jar'

local status, jdtls = pcall(require, 'jdtls')
if not status then
  vim.notify('JDTLS not installed! Run :MasonInstall jdtls', vim.log.levels.ERROR)
  return
end

local config = {
  cmd = {
    'java', -- 🛑 Danger 3: Must be Java 11+ (check with java -version)
    '-Declipse.application=org.eclipse.jdt.ls.core.id1',
    '-Dosgi.bundles.defaultStartLevel=4',
    '-Declipse.product=org.eclipse.jdt.ls.core.product',
    '-Dlog.protocol=true',
    '-Dlog.level=ALL',
    '-Xmx1g', -- 🛑 Danger 4: Increase if working with large projects
    '--add-modules=ALL-SYSTEM',
    '--add-opens',
    'java.base/java.util=ALL-UNNAMED',
    '--add-opens',
    'java.base/java.lang=ALL-UNNAMED',
    '-javaagent:' .. lombok_path,
    '-jar',
    vim.fn.glob(home .. '/.local/share/nvim/mason/packages/jdtls/plugins/org.eclipse.equinox.launcher_*.jar'), -- 🛑 Danger 5: JAR version mismatch
    '-configuration',
    home .. '/.local/share/nvim/mason/packages/jdtls/config_win', -- 🛑 Danger 6: Must be config_win for Windows
    '-data',
    workspace_dir, -- 🛑 Danger 7: Directory permissions issues
  },

  root_dir = require('jdtls.setup').find_root { '.git', 'mvnw', 'gradlew', 'pom.xml', 'build.gradle' },

  settings = {
    java = {
      signatureHelp = { enabled = true },
      extendedClientCapabilities = jdtls.extendedClientCapabilities,
      maven = {
        downloadSources = true,
      },
      referencesCodeLens = {
        enabled = true,
      },
      references = {
        includeDecompiledSources = true,
      },
      inlayHints = {
        parameterNames = {
          enabled = 'all',
        },
      },
      format = {
        enabled = false, -- 🛑 Danger 8: Disabled formatting might conflict with other plugins
      },
    },
  },

  init_options = {
    bundles = {
      vim.fn.glob(lombok_path, 1), -- 🛑 Danger 9: Lombok bundle might need path adjustment
    },
  },
}

require('jdtls').start_or_attach(config)

-- Keymaps might conflict with other plugins
vim.keymap.set('n', '<leader>co', "<Cmd>lua require'jdtls'.organize_imports()<CR>", { desc = 'Organize Imports' })
vim.keymap.set('n', '<leader>crv', "<Cmd>lua require('jdtls').extract_variable()<CR>", { desc = 'Extract Variable' })
vim.keymap.set('v', '<leader>crv', "<Esc><Cmd>lua require('jdtls').extract_variable(true)<CR>", { desc = 'Extract Variable' })
vim.keymap.set('n', '<leader>crc', "<Cmd>lua require('jdtls').extract_constant()<CR>", { desc = 'Extract Constant' })
vim.keymap.set('v', '<leader>crc', "<Esc><Cmd>lua require('jdtls').extract_constant(true)<CR>", { desc = 'Extract Constant' })
vim.keymap.set('v', '<leader>crm', "<Esc><Cmd>lua require('jdtls').extract_method(true)<CR>", { desc = 'Extract Method' })
