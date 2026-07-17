import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "page", "search"]

  connect() {
    this.timeout = null
    this.restoreSearchFocus()
  }

  disconnect() {
    this.clearPendingSubmit()
  }

  submit() {
    this.rememberSearchFocus()
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

  rememberSearchFocus() {
    try {
      window.sessionStorage.setItem(this.searchFocusStorageKey, "true")
    } catch (_error) {
      // Focus restoration is progressive enhancement.
    }
  }

  restoreSearchFocus() {
    if (!this.hasSearchTarget) return

    try {
      if (window.sessionStorage.getItem(this.searchFocusStorageKey) !== "true") return
      window.sessionStorage.removeItem(this.searchFocusStorageKey)
    } catch (_error) {
      return
    }

    requestAnimationFrame(() => {
      this.searchTarget.focus()
      this.searchTarget.setSelectionRange(this.searchTarget.value.length, this.searchTarget.value.length)
    })
  }

  get searchFocusStorageKey() {
    return `gridline.tableSearch.${this.frameId}.restoreFocus`
  }

  get frameId() {
    return this.element.closest("turbo-frame")?.id || this.formTarget.action
  }
}
