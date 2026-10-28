import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "lista"]
  static values = { url: String }

  buscar() {
    clearTimeout(this.timer)
    const termo = this.inputTarget.value.trim()
    if (termo.length < 2) return this.fechar()
    this.timer = setTimeout(() => this.carregar(termo), 250)
  }

  async carregar(termo) {
    const resposta = await fetch(`${this.urlValue}?q=${encodeURIComponent(termo)}`, {
      headers: { Accept: "text/html" }
    })
    if (!resposta.ok) return
    const html = await resposta.text()
    if (termo !== this.inputTarget.value.trim()) return
    this.listaTarget.innerHTML = html
    this.listaTarget.classList.remove("hidden")
  }

  fechar() {
    this.listaTarget.classList.add("hidden")
  }

  fecharFora(event) {
    if (!this.element.contains(event.target)) this.fechar()
  }
}
