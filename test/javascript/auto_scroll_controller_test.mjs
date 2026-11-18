import { test } from "node:test"
import assert from "node:assert/strict"
import { readFileSync } from "node:fs"
import vm from "node:vm"

function carousel({ autoplay = true, reducedMotion = false } = {}) {
  let tick
  const state = { active: false, interval: null, moves: [] }
  const context = vm.createContext({
    Controller: class {}, document: { hidden: false },
    window: {
      matchMedia: () => ({ matches: reducedMotion }),
      clearInterval: () => { state.active = false },
      setInterval: (callback, interval) => { tick = callback; state.interval = interval; state.active = true; return 1 }
    }
  })
  const source = readFileSync(new URL("../../app/javascript/controllers/auto_scroll_controller.js", import.meta.url), "utf8")
  vm.runInContext(source.replace(/^import .*\n/, "").replace("export default class", "globalThis.Carousel = class"), context)
  const controller = new context.Carousel()
  controller.autoplayValue = autoplay
  controller.toggleTargets = []
  controller.iconTargets = []
  controller.move = direction => state.moves.push(direction)
  return { controller, state, tick: () => tick(), document: context.document }
}

test("beneficios iniciam automaticamente e permitem pausa retomada e desconexao", () => {
  const c = carousel()
  c.controller.connect()
  assert.equal(c.state.active, true)
  assert.equal(c.state.interval, 4500)
  c.tick()
  assert.deepEqual(c.state.moves, [1])
  c.document.hidden = true
  c.tick()
  assert.deepEqual(c.state.moves, [1])
  c.controller.pause()
  assert.equal(c.state.active, false)
  c.controller.resume()
  assert.equal(c.state.active, true)
  c.controller.toggle()
  assert.equal(c.state.active, false)
  c.controller.resume()
  assert.equal(c.state.active, false)
  c.controller.toggle()
  assert.equal(c.state.active, true)
  c.controller.disconnect()
  assert.equal(c.state.active, false)
})

test("movimento reduzido e carrosseis sem autoplay nao iniciam sozinhos", () => {
  for (const options of [{ reducedMotion: true }, { autoplay: false }]) {
    const c = carousel(options)
    c.controller.connect()
    assert.equal(c.state.active, false)
  }
})
