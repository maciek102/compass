import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["select"]

  select(event) {
    const value = event.currentTarget.dataset.value

    // ustawienie select
    this.selectTarget.value = value

    // podświetlenie kafelków
    this.element.querySelectorAll(".tile").forEach(tile => {
      tile.classList.toggle("active", tile.dataset.value === value)
    })
  }
}
