import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    url: String,
    minChars: { type: Number, default: 3 },
    placeholder: { type: String, default: "..." },
    delay: { type: Number, default: 300 }
  }

  static targets = [
    "input",
    "inputContainer",
    "dropdown",
    "results",
    "hiddenSelect",
    "selectedDisplay",
    "selectedLabel",
    "clearButton"
  ]

  connect() {
    this.timeout = null
    this.isOpen = false

    // obsługa kliknięć poza komponentem
    this.boundHandleClickOutside = this.handleClickOutside.bind(this)
    document.addEventListener('click', this.boundHandleClickOutside)
  }

  disconnect() {
    document.removeEventListener('click', this.boundHandleClickOutside)
    clearTimeout(this.timeout)
  }

  handleFocus() {
    if (this.inputTarget.value.length >= this.minCharsValue) {
      this.openDropdown()
    }
  }

  search(event) {
    const query = event.target.value.trim()
    
    clearTimeout(this.timeout)
    
    if (query.length < this.minCharsValue) {
      this.showPlaceholder()
      return
    }
    
    this.timeout = setTimeout(() => {
      this.performSearch(query)
    }, this.delayValue)
  }

  async performSearch(query) {
    try {
      this.showLoading()
      
      const params = new URLSearchParams({ q: query })
      const url = `${this.urlValue}?${params.toString()}`
            
      const response = await fetch(url, {
        headers: {
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest'
        }
      })
      
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`)
      }
      
      const data = await response.json()
      this.displayResults(data.results || [])
    } catch (error) {
      console.error('Search error:', error)
      this.showError()
    }
  }

  displayResults(results) {
    this.resultsTarget.innerHTML = ''
    
    if (results.length === 0) {
      this.showNoResults()
      return
    }
    
    results.forEach(result => {
      const item = document.createElement('div')
      item.className = 'async-select-item'
      item.setAttribute('data-id', result.id)
      item.setAttribute('data-text', result.text)
      item.setAttribute('data-action', 'click->async-select#selectItem')
      
      if (result.html) {
        item.innerHTML = result.html
      } else {
        item.textContent = result.text
      }
      
      this.resultsTarget.appendChild(item)
    })
    
    this.openDropdown()
  }

  selectItem(event) {
    const item = event.currentTarget
    const id = item.dataset.id
    const text = item.dataset.text || item.textContent.trim()
    
    // aktualizacja hidden select
    this.hiddenSelectTarget.value = id
    
    // aktualizacja tekstu
    this.selectedLabelTarget.textContent = text

    this.selectedDisplayTarget.style.display = 'flex'
    this.inputContainerTarget.style.display = 'none'
    this.inputTarget.value = ''
    
    this.closeDropdown()
    
    this.element.dispatchEvent(new CustomEvent('async-select:change', {
      detail: { id, text },
      bubbles: true
    }))
  }

  clear(event) {
    event.stopPropagation()
    
    this.hiddenSelectTarget.value = ''
    
    this.selectedDisplayTarget.style.display = 'none'
    this.inputContainerTarget.style.display = 'block'
    this.inputTarget.value = ''
    this.inputTarget.focus()
    
    this.closeDropdown()
    
    this.element.dispatchEvent(new CustomEvent('async-select:clear', {
      bubbles: true
    }))
  }

  showPlaceholder() {
    this.resultsTarget.innerHTML = `
      <div class="async-select-message">
        ${this.placeholderValue}
      </div>
    `
    this.closeDropdown()
  }

  showLoading() {
    this.resultsTarget.innerHTML = `
      <div class="async-select-message async-select-loading">
        <span class="spinner-border spinner-border-sm me-2"></span>
        Wyszukiwanie...
      </div>
    `
    this.openDropdown()
  }

  showNoResults() {
    this.resultsTarget.innerHTML = `
      <div class="async-select-message async-select-no-results">
        Nie znaleziono wyników
      </div>
    `
    this.openDropdown()
  }

  showError() {
    this.resultsTarget.innerHTML = `
      <div class="async-select-message async-select-error">
        Wystąpił błąd podczas wyszukiwania
      </div>
    `
    this.openDropdown()
  }

  openDropdown() {
    this.dropdownTarget.style.display = 'block'
    this.isOpen = true
  }

  closeDropdown() {
    this.dropdownTarget.style.display = 'none'
    this.isOpen = false
  }

  handleClickOutside(event) {
    if (!this.element.contains(event.target) && this.isOpen) {
      this.closeDropdown()
    }
  }
}
