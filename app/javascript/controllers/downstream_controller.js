import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String }

  connect() {
    this.trigger()
  }

  trigger() {
    if (!this.hasUrlValue) return

    fetch(this.urlValue, {
      method: "POST",
      credentials: "same-origin",
      headers: { "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content }
    }).then(response => {
      if (response.status === 409) this.retry()
    }).catch(() => {})
  }

  retry() {
    setTimeout(() => this.trigger(), 30000)
  }
}