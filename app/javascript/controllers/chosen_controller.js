import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  async connect() {
    await this.waitForDependencies()

    console.log("chosen controller connected")
    
    this.$select = $(this.element)
    this.$select
      .chosen({
        allow_single_deselect: true,
        no_results_text: "Brak elementów",
        width: "100%",
        placeholder_text_multiple: "Kliknij i wybierz (możesz wskazać wiele)",
        placeholder_text_single: "Kliknij i wybierz"
      })
      .on("change.chosenStimulusBridge", (e) => {
        if (e.originalEvent && e.originalEvent._stimulus) return
        const nativeEvent = new Event("change", { bubbles: true })
        nativeEvent._stimulus = true
        this.element.dispatchEvent(nativeEvent)
      })
  }
  
  waitForDependencies() {
    return new Promise((resolve) => {
      const checkDependencies = () => {
        if (typeof $ !== 'undefined' && typeof $.fn.chosen === 'function') {
          resolve()
        } else {
          setTimeout(checkDependencies, 50)
        }
      }
      checkDependencies()
    })
  }
  
  disconnect() {
    if (this.$select && typeof this.$select.chosen === 'function') {
      this.$select.off(".chosenStimulusBridge")
      this.$select.chosen("destroy")
    }
  }
}