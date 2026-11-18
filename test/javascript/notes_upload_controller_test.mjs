import { test } from "node:test"
import assert from "node:assert/strict"
import { readFileSync } from "node:fs"
import vm from "node:vm"

function controller(rows = []) {
  const source = readFileSync(new URL("../../app/javascript/controllers/notes_upload_controller.js", import.meta.url), "utf8")
  const context = vm.createContext({ Controller: class {} })
  vm.runInContext(source.replace(/^import .*\n/, "").replace("export default class", "globalThis.Classe = class"), context)
  const c = new context.Classe()
  c.namesTarget = { value: "" }
  c.pickerTarget = { files: [], value: "selecionado" }
  c.rowsTarget = { querySelectorAll: () => rows }
  c.statusTarget = { textContent: "" }
  c.added = []
  c.addRow = (name, file) => c.added.push({ name, file })
  return c
}

test("selecao multipla associa a lista de nomes a cada foto", () => {
  const c = controller()
  c.namesTarget.value = "Pera, Melão"
  c.pickerTarget.files = ["pera.png", "melao.png"].map(name => ({ name, type: "image/png", size: 100 }))
  c.addFiles()
  assert.deepEqual(c.added.map(row => row.name), ["Pera", "Melão"])
  assert.equal(c.added[1].file.name, "melao.png")
  assert.equal(c.pickerTarget.value, "")
})

test("usa nome do arquivo e rejeita tipos e tamanhos invalidos", () => {
  const c = controller()
  c.pickerTarget.files = [
    { name: "rosa_vermelha.png", type: "image/png", size: 100 },
    { name: "invalido.svg", type: "image/svg+xml", size: 100 },
    { name: "grande.png", type: "image/png", size: 6 * 1024 * 1024 }
  ]
  c.addFiles()
  assert.equal(c.added.length, 1)
  assert.equal(c.added[0].name, "rosa vermelha")
  assert.match(c.statusTarget.textContent, /2 arquivo\(s\) recusado/)
})

test("aplica lista aos novos cards e cria notas sem fotos para nomes restantes", () => {
  const input = { value: "Antigo" }
  const c = controller([{ querySelector: () => input }])
  c.namesTarget.value = "Frésia\nRosa; Jasmim"
  c.applyNames()
  assert.equal(input.value, "Frésia")
  assert.deepEqual(c.added.map(row => row.name), ["Rosa", "Jasmim"])
  assert.equal(c.added[0].file, undefined)
})
