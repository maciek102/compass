import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    delay: { type: Number, default: 0 } // opóźnienie w ms przed submitowaniem
  }

  connect() {
    // Jeśli kontroler jest na formie, użyj tego
    // Jeśli na divie, znajdź formę rodzica
    this.form = this.element.tagName === "FORM" ? this.element : this.element.closest("form")
    
    if (!this.form) {
      console.warn("[auto-submit] Form not found")
      return
    }

    // Nasłuchuj na WSZYSTKIE zmiany w formie (select, input, textarea)
    this.form.addEventListener("change", (e) => this.handleChange(e))
    this.form.addEventListener("input", (e) => this.handleChange(e))
  }

  // Obsługa zdarzenia zmiany
  handleChange(event) {
    // Sprawdź czy target to input, select lub textarea
    const target = event.target
    if (["INPUT", "SELECT", "TEXTAREA"].includes(target.tagName)) {
      this.scheduleSubmit()
    }
  }

  // Zaplanuj submit z opóźnieniem lub wykonaj od razu
  scheduleSubmit() {
    clearTimeout(this.submitTimeout)
    
    if (this.delayValue > 0) {
      this.submitTimeout = setTimeout(() => {
        this.submitForm()
      }, this.delayValue)
    } else {
      this.submitForm()
    }
  }

  // Wykonaj submit formularza
  submitForm() {
    if (this.form) {
      this.form.requestSubmit()
    }
  }

  // Cleanup
  disconnect() {
    if (this.submitTimeout) {
      clearTimeout(this.submitTimeout)
    }
  }
}
