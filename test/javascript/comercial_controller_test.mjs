import { test } from "node:test"
import assert from "node:assert/strict"
import { readFileSync } from "node:fs"
import vm from "node:vm"

function controlador(arquivo) {
  const fonte = readFileSync(new URL(`../../app/javascript/controllers/${arquivo}_controller.js`, import.meta.url), "utf8")
  const contexto = vm.createContext({ Controller: class {}, Option: class { constructor(text, value) { this.text = text; this.value = value } } })
  vm.runInContext(fonte.replace(/^import .*\n/, "").replace("export default class", "globalThis.Classe = class"), contexto)
  return new contexto.Classe()
}

test("calculadora converte borrifadas em ml e rejeita entradas invalidas", () => {
  const c = controlador("borrifadas")
  c.fatorValue = 16
  c.quantidadeTarget = { value: "80" }
  c.resultadoTarget = { textContent: "" }
  c.calcular()
  assert.equal(c.resultadoTarget.textContent, "Volume estimado: 5 ml.")
  for (const entrada of ["", "-1", "1.5", "abc"]) {
    c.quantidadeTarget.value = entrada
    c.calcular()
    assert.match(c.resultadoTarget.textContent, /Informe uma quantidade inteira/)
  }
  c.quantidadeTarget.value = "0"
  c.calcular()
  assert.equal(c.resultadoTarget.textContent, "Volume estimado: 0 ml.")
})

test("troca de tamanho atualiza preco volume borrifadas e parcela", () => {
  const c = controlador("variante")
  for (const alvo of ["preco", "original", "porMl", "borrifadas", "parcela"]) {
    c[`has${alvo[0].toUpperCase()}${alvo.slice(1)}Target`] = true
    c[`${alvo}Target`] = { textContent: "" }
  }
  c.hasSelecionadaTarget = true
  c.selecionadaTarget = { value: "" }
  c.atualizar({ target: { tagName: "INPUT", value: "8", dataset: {
    precoFormatado: "R$ 80,00", precoOriginal: "R$ 100,00", porMl: "R$ 8,00/ml",
    borrifadas: "Aproximadamente 160 borrifadas", parcela: "Em até 6x"
  } } })
  assert.equal(c.precoTarget.textContent, "R$ 80,00")
  assert.equal(c.porMlTarget.textContent, "R$ 8,00/ml")
  assert.equal(c.borrifadasTarget.textContent, "Aproximadamente 160 borrifadas")
  assert.equal(c.selecionadaTarget.value, "8")
})

test("quantidade respeita os limites e acompanha o estoque ao mudar tamanho", () => {
  const c = controlador("variante")
  c.hasQuantidadeTarget = true
  c.quantidadeTarget = { value: "1", max: "5" }
  c.diminuir()
  assert.equal(Number(c.quantidadeTarget.value), 1)
  c.aumentar()
  assert.equal(Number(c.quantidadeTarget.value), 2)
  c.quantidadeTarget.value = "99"
  c.ajustarQuantidade()
  assert.equal(Number(c.quantidadeTarget.value), 5)
  c.atualizar({ target: { tagName: "INPUT", value: "2", dataset: { quantidadeMaxima: "2" } } })
  assert.equal(Number(c.quantidadeTarget.value), 2)
  c.quantidadeTarget.value = "-3"
  c.ajustarQuantidade()
  assert.equal(Number(c.quantidadeTarget.value), 1)
})


test("categoria alterna origens comuns e de nicho sem conservar uma origem incompativel", () => {
  const c = controlador("produto_origem")
  c.comunsValue = { arabe: "Árabes", importado: "Importados" }
  c.nichoValue = { xerjoff: "Xerjoff", nishane: "Nishane", sospiro: "Sospiro" }
  c.cuidadosValue = ["body_splash", "hidratante"]
  c.campoPublicoTarget = { hidden: false }
  c.publicoTarget = { disabled: false }
  c.categoriaTarget = { value: "masculino" }
  c.origemTarget = { value: "arabe", options: [], replaceChildren(...options) { this.options = options }, add(option) { this.options.push(option) } }
  c.connect()
  assert.equal(c.campoPublicoTarget.hidden, true)
  assert.equal(c.publicoTarget.disabled, true)
  assert.equal(c.origemTarget.value, "arabe")
  assert.deepEqual(c.origemTarget.options.map(o => o.value), ["", "arabe", "importado"])
  c.categoriaTarget.value = "nicho"
  c.atualizar()
  assert.equal(c.origemTarget.value, "")
  assert.deepEqual(c.origemTarget.options.map(o => o.value), ["", "xerjoff", "nishane", "sospiro"])
  c.origemTarget.value = "nishane"
  c.connect()
  assert.equal(c.origemTarget.value, "nishane")
  for (const categoria of ["feminino", "unissex", "masculino"]) {
    c.categoriaTarget.value = categoria
    c.atualizar()
    assert.deepEqual(c.origemTarget.options.map(o => o.value), ["", "arabe", "importado"])
  }
  c.categoriaTarget.value = "body_splash"
  c.atualizar()
  assert.equal(c.campoPublicoTarget.hidden, false)
  assert.equal(c.publicoTarget.disabled, false)
})
