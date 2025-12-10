import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["list"]

  add(event) {
    event.preventDefault()
    const row = document.createElement('div')
    row.className = 'attribute-row'
    row.innerHTML = `
      <input type="text" name="variant[custom_attributes_array][][key]" placeholder="Klucz" class="form-control">
      <input type="text" name="variant[custom_attributes_array][][value]" placeholder="Wartość" class="form-control">
      <button type="button" class="action-btn" data-action="click->custom-attributes#remove">X</button>
    `
    this.listTarget.appendChild(row)
  }

  remove(event) {
    event.preventDefault()
    event.target.closest('.attribute-row').remove()
  }
}