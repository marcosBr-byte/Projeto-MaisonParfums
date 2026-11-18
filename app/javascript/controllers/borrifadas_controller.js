import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["quantidade", "resultado"]
  static values = { fator: Number }

  calcular() {
    const entrada = this.quantidadeTarget.value.trim()
    const quantidade = Number(entrada)
    if (!entrada || !Number.isSafeInteger(quantidade) || quantidade < 0 || this.fatorValue <= 0) {
      this.resultadoTarget.textContent = "Informe uma quantidade inteira de borrifadas, a partir de zero."
      return
    }
    const volume = (quantidade / this.fatorValue).toLocaleString("pt-BR", { maximumFractionDigits: 2 })
    this.resultadoTarget.textContent = `Volume estimado: ${volume} ml.`
  }
}
