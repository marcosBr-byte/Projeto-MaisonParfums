import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["image", "link", "thumbnail"]

  select(event) {
    const button = event.currentTarget
    this.imageTarget.src = button.dataset.imageUrl
    this.imageTarget.alt = button.dataset.imageAlt
    this.linkTarget.href = button.dataset.imageUrl
    this.thumbnailTargets.forEach(thumbnail => thumbnail.setAttribute("aria-pressed", String(thumbnail === button)))
  }
}
