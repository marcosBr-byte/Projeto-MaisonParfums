import { test } from "node:test"
import assert from "node:assert/strict"
import { readFileSync } from "node:fs"
import vm from "node:vm"

function search() {
  const pending = []
  const context = vm.createContext({ Controller: class {}, AbortController, clearTimeout, setTimeout,
    fetch: (url, options) => new Promise(resolve => pending.push({ url, options, resolve }))
  })
  const source = readFileSync(new URL("../../app/javascript/controllers/busca_controller.js", import.meta.url), "utf8")
  vm.runInContext(source.replace(/^import .*\n/, "").replace("export default class", "globalThis.Search = class"), context)
  const c = new context.Search()
  c.urlValue = "/busca/sugestoes"
  c.inputTarget = { value: "rosa", attributes: {}, setAttribute(key, value) { this.attributes[key] = value } }
  const classes = new Set(["hidden"])
  c.listaTarget = { innerHTML: "", classList: { add: key => classes.add(key), remove: key => classes.delete(key), contains: key => classes.has(key) } }
  return { c, pending, classes }
}

const response = html => ({ ok: true, text: async () => html })

test("sugestoes novas substituem a busca anterior sem aceitar respostas atrasadas", async () => {
  const { c, pending, classes } = search()
  const first = c.carregar("rosa")
  c.cancelar()
  c.inputTarget.value = "sandalo"
  const second = c.carregar("sandalo")
  pending[1].resolve(response("Sândalo"))
  await second
  assert.equal(c.listaTarget.innerHTML, "Sândalo")
  assert.equal(classes.has("hidden"), false)
  pending[0].resolve(response("Rosa"))
  await first
  assert.equal(c.listaTarget.innerHTML, "Sândalo")
  c.fechar()
  assert.equal(classes.has("hidden"), true)
  assert.equal(c.inputTarget.attributes["aria-expanded"], "false")
})

test("fechar a busca impede uma resposta pendente de reabrir as sugestoes", async () => {
  const { c, pending, classes } = search()
  const loading = c.carregar("rosa")
  c.fechar()
  assert.equal(pending[0].options.signal.aborted, true)
  pending[0].resolve(response("Rosa"))
  await loading
  assert.equal(classes.has("hidden"), true)
  assert.equal(c.listaTarget.innerHTML, "")
})
