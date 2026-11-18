import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "lista"]
  static values = { url: String }

  disconnect() {
    this.cancelar()
  }

  cancelar() {
    clearTimeout(this.timer)
    this.request?.abort()
  }

  buscar() {
    this.cancelar()
    const termo = this.inputTarget.value.trim()
    if (termo.length < 2) return this.fechar()
    this.timer = setTimeout(() => this.carregar(termo), 250)
  }

  async carregar(termo) {
    const request = new AbortController()
    this.request = request
    try {
      const resposta = await fetch(`${this.urlValue}?q=${encodeURIComponent(termo)}`, {
        headers: { Accept: "text/html" }, signal: request.signal
      })
      if (!resposta.ok) throw new Error("Busca indisponível")
      const html = await resposta.text()
      if (request.signal.aborted || termo !== this.inputTarget.value.trim()) return
      this.listaTarget.innerHTML = html
      this.listaTarget.classList.remove("hidden")
      this.inputTarget.setAttribute("aria-expanded", "true")
    } catch (error) {
      if (request.signal.aborted) return
      this.fechar()
    }
  }

  fechar() {
    this.cancelar()
    this.listaTarget.classList.add("hidden")
    this.inputTarget.setAttribute("aria-expanded", "false")
  }

  teclado(event) {
    if (event.key === "Escape") {
      this.inputTarget.focus()
      this.fechar()
      return
    }
    if (!["ArrowDown", "ArrowUp"].includes(event.key) || this.listaTarget.classList.contains("hidden")) return
    const links = Array.from(this.listaTarget.querySelectorAll("a"))
    if (!links.length) return
    event.preventDefault()
    const atual = links.indexOf(document.activeElement)
    const proximo = atual < 0 ? (event.key === "ArrowDown" ? 0 : links.length - 1) : (atual + (event.key === "ArrowDown" ? 1 : -1) + links.length) % links.length
    links[proximo].focus()
  }

  fecharFora(event) {
    if (!this.element.contains(event.target)) this.fechar()
  }
}
