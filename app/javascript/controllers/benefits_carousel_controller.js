import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["track", "slide"]

  connect() {
    window.clearInterval(this.timer)
    if (this.slideTargets.length > 1) {
      this.timer = window.setInterval(() => this.rotate(), 5000)
    }
  }

  disconnect() {
    window.clearInterval(this.timer)
    this.animations?.forEach(animation => animation.cancel())
  }

  rotate() {
    const slides = this.slideTargets
    if (slides.length < 2) return
    this.animations?.forEach(animation => animation.cancel())
    const positions = slides.map(slide => slide.getBoundingClientRect())
    this.trackTarget.append(slides[0])
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) return
    this.animations = slides.map((slide, index) => {
      const position = slide.getBoundingClientRect()
      return slide.animate([
        { transform: `translate(${positions[index].left - position.left}px, ${positions[index].top - position.top}px)` },
        { transform: "translate(0, 0)" }
      ], { duration: 650, easing: "ease-in-out" })
    })
  }
}
