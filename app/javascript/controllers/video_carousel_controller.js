import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["slide", "dot", "progress", "counter"]

  connect() {
    this.index = 0
    this.show()
  }

  disconnect() {
    this.slideTargets.forEach(slide => slide.querySelector("video").pause())
  }

  next(event) {
    this.navigate(this.index + 1, event)
  }

  previous(event) {
    this.navigate(this.index - 1, event)
  }

  goTo(event) {
    this.navigate(event.params.index, event)
  }

  navigate(index, event) {
    // Keep the native video player's arrow-key controls available.
    if (event?.type === "keydown" && event.target.tagName === "VIDEO") return
    if (!this.slideTargets.length) return
    event?.preventDefault()
    this.index = (index + this.slideTargets.length) % this.slideTargets.length
    this.show()
  }

  touchStart(event) {
    const touch = event.changedTouches[0]
    this.touchOrigin = { x: touch.clientX, y: touch.clientY }
  }

  touchEnd(event) {
    if (!this.touchOrigin) return
    const touch = event.changedTouches[0]
    const dx = touch.clientX - this.touchOrigin.x
    const dy = touch.clientY - this.touchOrigin.y
    this.touchOrigin = null
    if (Math.abs(dx) > 60 && Math.abs(dx) > Math.abs(dy) * 1.5) {
      this.navigate(this.index + (dx < 0 ? 1 : -1))
    }
  }

  updateProgress(event) {
    const video = event.target
    if (video !== this.slideTargets[this.index]?.querySelector("video")) return
    const fraction = Number.isFinite(video.duration) && video.duration > 0 ? video.currentTime / video.duration : 0
    if (this.hasProgressTarget) this.progressTarget.style.transform = `scaleX(${Math.min(1, Math.max(0, fraction))})`
  }

  show() {
    if (this.hasProgressTarget) this.progressTarget.style.transform = "scaleX(0)"
    if (this.hasCounterTarget) this.counterTarget.textContent = `Vídeo ${this.index + 1} de ${this.slideTargets.length}`
    this.slideTargets.forEach((slide, index) => {
      const video = slide.querySelector("video")
      const active = index === this.index
      const total = this.slideTargets.length
      const previous = index === (this.index - 1 + total) % total
      const next = index === (this.index + 1) % total
      slide.hidden = !(active || previous || next)
      slide.dataset.position = active ? "active" : previous ? "previous" : next ? "next" : "hidden"
      slide.inert = !active
      slide.setAttribute("aria-hidden", String(!active))
      if (active) {
        const playback = video.play()
        playback?.catch(() => {})
      } else {
        video.pause()
        video.currentTime = 0
      }
    })
    this.dotTargets.forEach((dot, index) => {
      dot.setAttribute("aria-current", String(index === this.index))
    })
  }
}
