import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["barra", "botaoReceita", "botaoPedidos", "legenda"]
  receita() { this.mostrar("receita") }
  pedidos() { this.mostrar("pedidos") }
  mostrar(metrica) {
    this.barraTargets.forEach(barra => { barra.style.height = `${Number(barra.dataset[metrica]) || 0}%` })
    this.botaoReceitaTarget.setAttribute("aria-pressed", String(metrica === "receita"))
    this.botaoPedidosTarget.setAttribute("aria-pressed", String(metrica === "pedidos"))
    this.legendaTarget.textContent = metrica === "receita" ? "Vendas confirmadas por dia" : "Todos os pedidos por dia"
  }
}
