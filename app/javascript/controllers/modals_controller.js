import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
  }

  closeByOverlay(e){
    if (e.target.classList.contains("modal-overlay")) {
      e.preventDefault();
      const modal = document.getElementById("modal");
      modal.innerHTML = "";
    }
  }

  close(e){
    e.preventDefault();
    const modal = document.getElementById("modal");
    modal.innerHTML = "";
  }
}
