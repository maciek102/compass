import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["quantity", "strategy", "items"]

  update() {
    const quantity = this.quantityTarget.value
    const strategy = this.strategyTarget.value
    const stockOperationId = this.element.dataset.stockOperationId

    fetch(`/stock_movements/prepare_items`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector("[name='csrf-token']").content
      },
      body: JSON.stringify({
        stock_operation_id: stockOperationId,
        quantity: quantity,
        strategy: strategy
      })
    })
    .then(response => response.text())
    .then(html => {
      this.itemsTarget.innerHTML = html
    })
  }
}
