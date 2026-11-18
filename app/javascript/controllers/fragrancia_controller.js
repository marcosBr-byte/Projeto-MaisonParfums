import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["campo", "opcoes", "entrada", "contador", "acao"]
  static values = { selecionadas: Array, sugestoes: Array }

  connect() {
    this.todas = []
    ;[...this.sugestoesValue, ...this.selecionadasValue].forEach((v) => this.incluir(v))
    this.render()
  }

  incluir(valor) {
    const existe = this.todas.some((v) => v.toLowerCase() === valor.toLowerCase())
    if (!existe) this.todas.push(valor)
  }

  teclar(event) {
    if (event.key === "Enter") {
      event.preventDefault()
      this.adicionar()
    }
  }

  alternar(event) {
    const valor = event.currentTarget.dataset.valor
    this.selecionadasValue = this.selecionadasValue.includes(valor)
      ? this.selecionadasValue.filter((v) => v !== valor)
      : [...this.selecionadasValue, valor]
    this.render()
  }

  adicionar() {
    const valor = this.entradaTarget.value.trim()
    if (!valor) return

    this.incluir(valor)
    const existente = this.todas.find((v) => v.toLowerCase() === valor.toLowerCase())
    if (!this.selecionadasValue.includes(existente)) {
      this.selecionadasValue = [...this.selecionadasValue, existente]
    }
    this.entradaTarget.value = ""
    this.render()
  }

  alternarTodas() {
    const todasMarcadas = this.selecionadasValue.length === this.todas.length
    this.selecionadasValue = todasMarcadas ? [] : [...this.todas]
    this.render()
  }

  render() {
    const marcadas = this.selecionadasValue
    this.campoTarget.value = marcadas.join(", ")

    const n = marcadas.length
    this.contadorTarget.textContent =
      n === 0 ? "Nenhuma fragrância selecionada"
      : n === 1 ? "1 fragrância selecionada"
      : `${n} fragrâncias selecionadas`

    this.acaoTarget.textContent = n === this.todas.length ? "Limpar" : "Selecionar todas"

    this.opcoesTarget.innerHTML = ""
    this.todas.forEach((valor) => {
      const ativo = marcadas.includes(valor)
      const botao = document.createElement("button")
      botao.type = "button"
      botao.textContent = valor
      botao.dataset.valor = valor
      botao.dataset.action = "fragrancia#alternar"
      botao.className = ativo
        ? "px-3 py-1.5 rounded-full border text-sm bg-[#485057] border-[#485057] text-white"
        : "px-3 py-1.5 rounded-full border text-sm bg-white border-[#D9DADD] text-[#485057] hover:border-[#748A9C]"
      this.opcoesTarget.appendChild(botao)
    })
  }
}