import { Controller } from "@hotwired/stimulus"

// Copies element text to the clipboard and shows a tiny “Copied” toast-badge nearby
export default class extends Controller {
    static targets = ["source"]
    connect() { this.toast = null }

    copy() {
        const text = this.sourceTarget?.textContent?.trim() || ""
        if (!text) return
        navigator.clipboard.writeText(text)
        this.showToast()
    }

    showToast() {
        if (this.toast) this.toast.remove()
        this.toast = document.createElement("span")
        this.toast.className = "badge text-bg-dark-subtle small ms-2"
        this.toast.textContent = "Copied"
        this.element.after(this.toast)
        setTimeout(() => this.toast?.remove(), 900)
    }
}
