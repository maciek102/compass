import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = {
    delay: { type: Number, default: 200 }
  }

  connect() {
    this.timeout = null
  }

  submitWithDebounce(event) {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => {
      this.element.requestSubmit && this.element.requestSubmit() 

    }, this.delayValue)
  }
}
