import { Controller } from "@hotwired/stimulus"

// kontroler do obsługi zagnieżdżonych formularzy (nested forms) - dodawanie i usuwanie wierszy
export default class extends Controller {
  connect() {
    console.log("nested button connected");
  }

  addNewRow(e) {
    console.log("add");

    var elem = $(e.target);
    if(!elem.hasClass("add_fields")){
      elem = $(e.target).closest("a.add_fields")
    }

    e.preventDefault();
    var time = new Date().getTime();
    var regexp = new RegExp(elem.data('id'), 'g');
    elem.prev().append(elem.data('fields').replace(regexp, time));

  }

  removeRow(e){
    console.log("remove");

    var elem = $(e.target);
    if(!elem.hasClass("remove_fields")){
      elem = $(e.target).closest("a.remove_fields")
    }

    elem.prev().find('input[type=hidden]').val(true);
    elem.closest('.row.nest').addClass("hidden");
    e.preventDefault();
  }
}
