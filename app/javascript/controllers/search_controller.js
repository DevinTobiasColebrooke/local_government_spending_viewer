import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "form" ]

  connect() {
    this.timeout = null
  }

  submit() {
    clearTimeout(this.timeout)
    // Wait 300ms after typing stops before submitting
    this.timeout = setTimeout(() => {
      this.element.requestSubmit()
    }, 300)
  }
}