# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin "jquery", to: "jquery.min.js", preload: true
pin "jquery_ujs", to: "jquery_ujs.js", preload: true
pin "bootstrap", to: "https://ga.jspm.io/npm:bootstrap@5.1.3/dist/js/bootstrap.esm.js"
pin "@popperjs/core", to: "https://ga.jspm.io/npm:@popperjs/core@2.11.2/lib/index.js"
pin "select2", to: "select2.js", preload: true
pin "chosen-jquery", to: "https://cdnjs.cloudflare.com/ajax/libs/chosen/1.8.7/chosen.jquery.min.js"
pin "trix"
pin "@rails/actiontext", to: "actiontext.esm.js"
pin "slim-select" # @2.9.0
pin "@zxing/browser", to: "https://cdn.jsdelivr.net/npm/@zxing/browser@0.1.4/+esm"
pin "@zxing/library", to: "https://cdn.jsdelivr.net/npm/@zxing/library@0.20.0/+esm"
pin_all_from "app/javascript/controllers", under: "controllers"
