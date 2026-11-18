import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["etapa", "progresso", "contador", "barra", "anterior", "proximo", "enviar", "erro"]

  connect() {
    this.indice = 0
    this.progressoTarget.hidden = false
    this.mostrar()
  }

  mostrar(focar = false) {
    this.etapaTargets.forEach((etapa, indice) => { etapa.hidden = indice !== this.indice })
    this.contadorTarget.textContent = `Etapa ${this.indice + 1} de ${this.etapaTargets.length}`
    this.barraTarget.value = this.indice + 1
    this.anteriorTarget.hidden = this.indice === 0
    this.proximoTarget.hidden = this.indice === this.etapaTargets.length - 1
    this.enviarTarget.hidden = !this.proximoTarget.hidden
    this.limparErro()
    if (focar) this.etapaTargets[this.indice].querySelector("legend").focus()
  }

  validar(indice) {
    const etapa = this.etapaTargets[indice]
    const selecionadas = etapa.querySelectorAll("input:checked").length
    const familias = etapa.dataset.campo === "familias"
    return familias ? selecionadas >= 1 && selecionadas <= 3 : selecionadas === 1
  }

  proximo() {
    if (!this.validar(this.indice)) {
      this.erroTarget.textContent = this.etapaTargets[this.indice].dataset.campo === "familias"
        ? "Escolha de uma a três famílias para continuar."
        : "Escolha uma opção para continuar."
      return
    }
    if (this.indice < this.etapaTargets.length - 1) this.indice += 1
    this.mostrar(true)
  }

  anterior() {
    this.indice = Math.max(0, this.indice - 1)
    this.mostrar(true)
  }

  enviar(event) {
    const invalida = this.etapaTargets.findIndex((_, indice) => !this.validar(indice))
    if (invalida < 0) return
    event.preventDefault()
    this.indice = invalida
    this.mostrar(true)
    this.erroTarget.textContent = "Revise esta resposta antes de ver suas sugestões."
  }

  limparErro() { this.erroTarget.textContent = "" }
}
