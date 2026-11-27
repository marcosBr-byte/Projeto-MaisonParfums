import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["introducao", "inicio", "formulario", "etapa", "progresso", "contador", "barra", "anterior", "proximo", "enviar", "erro"]

  static values = { revisar: Boolean }

  connect() {
    this.indice = 0
    this.progressoTarget.hidden = false
    this.introducaoTarget.hidden = this.revisarValue
    this.inicioTarget.hidden = false
    this.formularioTarget.hidden = !this.revisarValue
    this.mostrar()
  }

  iniciar() {
    this.introducaoTarget.hidden = true
    this.formularioTarget.hidden = false
    this.mostrar(true)
  }

  mostrar(focar = false) {
    this.etapaTargets.forEach((etapa, indice) => { etapa.hidden = indice !== this.indice })
    this.contadorTarget.textContent = `Pergunta ${this.indice + 1} de ${this.etapaTargets.length}`
    this.barraTarget.value = this.indice + 1
    this.anteriorTarget.hidden = this.indice === 0 && this.revisarValue
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
    if (this.indice === 0) {
      this.formularioTarget.hidden = true
      this.introducaoTarget.hidden = false
      this.inicioTarget.focus()
      return
    }
    this.indice -= 1
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
