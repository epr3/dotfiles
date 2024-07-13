local util = require 'lspconfig.util'

return {
  root_dir = util.root_pattern('angular.json', 'ng-package.json'),
}
