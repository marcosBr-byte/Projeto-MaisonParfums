import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["track", "toggle", "icon"]
  static values = { autoplay: { type: Boolean, default: false } }

  connect() {
    this.motion = window.matchMedia("(prefers-reduced-motion: reduce)")
    this.stopped = !this.autoplayValue
    this.updateButton()
    this.resume()
  }

  disconnect() { this.pause() }

  pause() { window.clearInterval(this.timer) }

  resume() {
    this.pause()
    if (this.stopped || this.motion.matches) return
    this.timer = window.setInterval(() => {
      if (!document.hidden) this.move(1)
    }, 4500)
  }

  next() { this.move(1) }
  previous() { this.move(-1) }

  move(direction) {
    const track = this.trackTarget
    const max = track.scrollWidth - track.clientWidth
    if (max < 2) return
    const item = track.firstElementChild
    const step = item.getBoundingClientRect().width + (parseFloat(getComputedStyle(track).columnGap) || 0)
    let left = track.scrollLeft + step * direction
    if (direction > 0 && track.scrollLeft >= max - 2) left = 0
    if (direction < 0 && track.scrollLeft <= 2) left = max
    track.scrollTo({ left, behavior: this.motion.matches ? "instant" : "smooth" })
  }

  toggle() {
    this.stopped = !this.stopped
    this.updateButton()
    if (this.stopped) this.pause()
    else this.resume()
  }

  updateButton() {
    this.toggleTargets.forEach(button => {
      button.setAttribute("aria-label", this.stopped ? "Reproduzir carrossel" : "Pausar carrossel")
      button.setAttribute("aria-pressed", String(this.stopped))
    })
    this.iconTargets.forEach(icon => { icon.textContent = this.stopped ? "play_arrow" : "pause" })
  }
}
