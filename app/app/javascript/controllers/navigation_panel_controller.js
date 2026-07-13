import { Controller } from "@hotwired/stimulus"

const storageKey = "gridline.navigationPanelOpen"

export default class extends Controller {
  static targets = ["button", "frame", "panel"]

  connect() {
    this.open = window.localStorage.getItem(storageKey) === "true"
    this.render()
  }

  toggle() {
    this.open = !this.open
    window.localStorage.setItem(storageKey, this.open ? "true" : "false")
    this.render()
  }

  render() {
    if (!this.hasButtonTarget || !this.hasPanelTarget) return

    this.frameTarget.classList.toggle("app-frame-nav-open", this.open)
    this.buttonTarget.setAttribute("aria-expanded", this.open ? "true" : "false")
    this.panelTarget.toggleAttribute("hidden", !this.open)
  }
}
