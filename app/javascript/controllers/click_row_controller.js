import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.element.querySelectorAll('[data-url]').forEach(row => {
      row.style.cursor = 'pointer'
    })
  }

  navigate(event) {
    if (event.target.closest('a, button, input, select, textarea, [data-no-navigate]')) {
      return
    }

    if (window.getSelection().toString()) {
      return
    }

    const row = event.target.closest('[data-url]')
    if (!row) return

    const url = row.dataset.url
    if (!url) return

    if (event.metaKey || event.ctrlKey) {
      window.open(url, '_blank')
    } else {
      if (window.Turbo) {
        Turbo.visit(url)
      } else {
        window.location.href = url
      }
    }
  }
}