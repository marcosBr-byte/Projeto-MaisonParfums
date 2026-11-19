import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["categoria", "origem", "campoPublico", "publico"]
  static values = { comuns: Object, nicho: Object, cuidados: Array }

  connect() {
    this.atualizar()
  }

  atualizar() {
    const cuidadosCorporais = this.cuidadosValue.includes(this.categoriaTarget.value)
    this.campoPublicoTarget.hidden = !cuidadosCorporais
    this.publicoTarget.disabled = !cuidadosCorporais

    const selecionada = this.origemTarget.value
    const opcoes = this.categoriaTarget.value === "nicho" ? this.nichoValue : this.comunsValue
    this.origemTarget.replaceChildren(new Option("Selecione", ""))
    for (const [valor, nome] of Object.entries(opcoes)) {
      this.origemTarget.add(new Option(nome, valor))
    }
    this.origemTarget.value = Object.hasOwn(opcoes, selecionada) ? selecionada : ""
  }
}
