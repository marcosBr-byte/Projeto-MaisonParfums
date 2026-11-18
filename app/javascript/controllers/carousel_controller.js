import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["slide", "dot"]
  static values = {
    index: { type: Number, default: 0 },
    interval: { type: Number, default: 5000 }
  }

  connect() {
    this.start()
  }

  disconnect() {
    this.stop()
  }

  next() {
    this.indexValue = (this.indexValue + 1) % this.slideTargets.length
    this.restart()
  }

  previous() {
    this.indexValue = (this.indexValue - 1 + this.slideTargets.length) % this.slideTargets.length
    this.restart()
  }

  goTo(event) {
    this.indexValue = event.params.index
    this.restart()
  }

  indexValueChanged() {
    this.slideTargets.forEach((slide, i) => {
      const ativo = i === this.indexValue
      slide.classList.toggle("opacity-100", ativo)
      slide.classList.toggle("opacity-0", !ativo)
      slide.classList.toggle("pointer-events-none", !ativo)
    })
    this.dotTargets.forEach((dot, i) => {
      const ativo = i === this.indexValue
      dot.classList.toggle("bg-white", ativo)
      dot.classList.toggle("bg-white/50", !ativo)
    })
  }

  start() {
    this.stop()
    if (this.slideTargets.length < 2) return
    this.timer = setInterval(() => {
      this.indexValue = (this.indexValue + 1) % this.slideTargets.length
    }, this.intervalValue)
  }

  stop() {
    clearInterval(this.timer)
  }

  restart() {
    this.stop()
    this.start()
  }
}