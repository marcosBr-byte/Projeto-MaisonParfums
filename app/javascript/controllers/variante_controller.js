import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["preco", "selecionada"]

  atualizar(event) {
    this.precoTarget.textContent = event.target.dataset.precoFormatado

    if (this.hasSelecionadaTarget) {
      this.selecionadaTarget.value = event.target.value
    }
  }
}
