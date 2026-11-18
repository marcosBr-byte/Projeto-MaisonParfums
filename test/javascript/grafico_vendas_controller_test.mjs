import { test } from "node:test"
import assert from "node:assert/strict"
import { readFileSync } from "node:fs"
import vm from "node:vm"

const contexto = vm.createContext({ Controller: class {} })
const fonte = readFileSync(new URL("../../app/javascript/controllers/grafico_vendas_controller.js", import.meta.url), "utf8")
vm.runInContext(fonte.replace(/^import .*\n/, "").replace("export default class", "globalThis.Classe = class"), contexto)

test("grafico alterna valores sem perder acessibilidade e trata dias sem movimento", () => {
  const c = new contexto.Classe()
  c.barraTargets = [{ dataset: { receita: "75", pedidos: "50" }, style: {} }, { dataset: { receita: "0", pedidos: "0" }, style: {} }]
  const botao = () => ({ atributos: {}, setAttribute(nome, valor) { this.atributos[nome] = valor } })
  c.botaoReceitaTarget = botao()
  c.botaoPedidosTarget = botao()
  c.legendaTarget = { textContent: "" }
  c.pedidos()
  assert.equal(c.barraTargets[0].style.height, "50%")
  assert.equal(c.barraTargets[1].style.height, "0%")
  assert.equal(c.botaoPedidosTarget.atributos["aria-pressed"], "true")
  assert.equal(c.botaoReceitaTarget.atributos["aria-pressed"], "false")
  c.receita()
  assert.equal(c.barraTargets[0].style.height, "75%")
  assert.equal(c.legendaTarget.textContent, "Vendas confirmadas por dia")
})
