import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["preco", "selecionada", "original", "porMl", "borrifadas", "parcela", "quantidade"]

  atualizar(event) {
    const el = event.target
    const origem = el.tagName === "SELECT" ? el.selectedOptions[0] : el
    if (!origem) return
    for (const [alvo, atributo] of [["preco", "precoFormatado"], ["original", "precoOriginal"], ["porMl", "porMl"], ["borrifadas", "borrifadas"], ["parcela", "parcela"]]) {
      const existe = `has${alvo[0].toUpperCase()}${alvo.slice(1)}Target`
      if (this[existe] && origem.dataset[atributo]) this[`${alvo}Target`].textContent = origem.dataset[atributo]
    }
    if (this.hasSelecionadaTarget) this.selecionadaTarget.value = el.value
    if (this.hasQuantidadeTarget && origem.dataset.quantidadeMaxima) {
      this.quantidadeTarget.max = origem.dataset.quantidadeMaxima
      this.ajustarQuantidade()
    }
  }

  diminuir() {
    this.alterarQuantidade(-1)
  }

  aumentar() {
    this.alterarQuantidade(1)
  }

  alterarQuantidade(delta) {
    this.ajustarQuantidade()
    this.quantidadeTarget.value = Number(this.quantidadeTarget.value) + delta
    this.ajustarQuantidade()
  }

  ajustarQuantidade() {
    if (!this.hasQuantidadeTarget) return
    const campo = this.quantidadeTarget
    const valor = Number(campo.value)
    campo.value = Math.min(Number(campo.max), Math.max(1, Number.isFinite(valor) ? Math.floor(valor) : 1))
  }

}
