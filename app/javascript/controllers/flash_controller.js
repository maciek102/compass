import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.autoHideFlash();
  }

  hideFlash(e) {
    e.preventDefault();
    
    $(this.element).css('-webkit-animation', 'fadeOut 400ms');
    $(this.element).bind('webkitAnimationEnd', function(){
      $(this).remove();
    }.bind(this.element));
    $(this.element).innerHTML = "";
  }

  autoHideFlash() {
    if (!this.element.classList.contains('without-auto-close')) {
      setTimeout(() => {
        this.hideFlash(new Event('auto-hide'));
      }, 2000);
    }
  }
}