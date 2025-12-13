import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["target"]

  toggle() {
    this.targetTargets.forEach(el => el.classList.toggle("hidden"))
  }
}