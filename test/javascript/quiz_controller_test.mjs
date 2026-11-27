import { test } from "node:test"
import assert from "node:assert/strict"
import { readFileSync } from "node:fs"
import vm from "node:vm"

const fonte = readFileSync(new URL("../../app/javascript/controllers/quiz_controller.js", import.meta.url), "utf8")
const contexto = vm.createContext({ Controller: class {} })
vm.runInContext(fonte.replace(/^import .*\n/, "").replace("export default class", "globalThis.Quiz = class"), contexto)

function preparar() {
  const quiz = new contexto.Quiz()
  quiz.revisarValue = false
  quiz.etapaTargets = ["categoria", "familias", "momento", "intensidade"].map(campo => ({
    dataset: { campo }, marcadas: 0, hidden: false,
    querySelectorAll() { return Array(this.marcadas).fill({}) },
    querySelector() { return { focus() {} } }
  }))
  for (const nome of ["introducao", "inicio", "formulario", "progresso", "contador", "barra", "anterior", "proximo", "enviar", "erro"]) {
    quiz[`${nome}Target`] = { hidden: true, textContent: "" }
  }
  quiz.connect()
  quiz.iniciar()
  return quiz
}

test("exige resposta antes de avançar e limita familias a tres", () => {
  const quiz = preparar()
  quiz.proximo()
  assert.equal(quiz.indice, 0)
  assert.match(quiz.erroTarget.textContent, /Escolha/)
  quiz.etapaTargets[0].marcadas = 1
  quiz.proximo()
  assert.equal(quiz.indice, 1)
  quiz.etapaTargets[1].marcadas = 4
  quiz.proximo()
  assert.equal(quiz.indice, 1)
  quiz.etapaTargets[1].marcadas = 3
  quiz.proximo()
  assert.equal(quiz.indice, 2)
})

test("navega ate resultado e voltar preserva escolhas", () => {
  const quiz = preparar()
  quiz.etapaTargets.forEach(etapa => { etapa.marcadas = 1 })
  for (let i = 0; i < 3; i++) quiz.proximo()
  assert.equal(quiz.enviarTarget.hidden, false)
  assert.equal(quiz.proximoTarget.hidden, true)
  assert.equal(quiz.barraTarget.value, 4)
  quiz.anterior()
  assert.equal(quiz.indice, 2)
  assert.equal(quiz.enviarTarget.hidden, true)
  assert.equal(quiz.etapaTargets[3].marcadas, 1)
})

test("impede envio incompleto e permite questionario valido", () => {
  const quiz = preparar()
  let bloqueado = false
  quiz.enviar({ preventDefault() { bloqueado = true } })
  assert.equal(bloqueado, true)
  quiz.etapaTargets.forEach(etapa => { etapa.marcadas = 1 })
  bloqueado = false
  quiz.enviar({ preventDefault() { bloqueado = true } })
  assert.equal(bloqueado, false)
})
