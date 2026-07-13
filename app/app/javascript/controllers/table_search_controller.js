import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "page"]

  connect() {
    this.timeout = null
  }

  disconnect() {
    this.clearPendingSubmit()
  }

  submit() {
    this.resetPage()
    this.clearPendingSubmit()
    this.timeout = setTimeout(() => this.submitForm(), 350)
  }

  submitNow() {
    this.resetPage()
    this.clearPendingSubmit()
    this.submitForm()
  }

  submitForm() {
    this.formTarget.requestSubmit()
  }

  resetPage() {
    if (this.hasPageTarget) {
      this.pageTarget.value = "1"
    }
  }

  clearPendingSubmit() {
    if (this.timeout) {
      clearTimeout(this.timeout)
      this.timeout = null
    }
  }
}
