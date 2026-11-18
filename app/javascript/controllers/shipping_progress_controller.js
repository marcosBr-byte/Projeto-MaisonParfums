import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["truck", "fill"]
  static values = { percent: Number }

  connect() {
    // Turbo replaces the page after quantity changes; carry the last position
    // forward so the truck travels to the new total rather than restarting.
    let previous = 0
    try { previous = Number(sessionStorage.getItem("maison-shipping-progress") || 0) } catch (_) {}
    this.draw(Math.max(0, Math.min(previous, 100)))
    this.frame = requestAnimationFrame(() => {
      this.frame = requestAnimationFrame(() => this.draw(this.percentValue))
    })
    try { sessionStorage.setItem("maison-shipping-progress", String(this.percentValue)) } catch (_) {}
  }

  disconnect() { cancelAnimationFrame(this.frame) }

  draw(percent) {
    this.truckTarget.style.left = `${percent}%`
    this.fillTarget.style.width = `${percent}%`
  }
}
