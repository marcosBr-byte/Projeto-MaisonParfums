import { test } from "node:test"
import assert from "node:assert/strict"
import { readFileSync } from "node:fs"
import vm from "node:vm"

const source = readFileSync(new URL("../../app/javascript/controllers/benefits_carousel_controller.js", import.meta.url), "utf8")

test("todos os avisos permanecem visiveis enquanto a ordem gira a cada cinco segundos", () => {
  let tick
  let delay
  let active = false
  const context = vm.createContext({ Controller: class {}, window: {
    matchMedia: () => ({ matches: false }),
    setInterval(callback, milliseconds) { tick = callback; delay = milliseconds; active = true; return 1 },
    clearInterval() { active = false }
  } })
  vm.runInContext(source.replace(/^import .*\n/, "").replace("export default class", "globalThis.Carousel = class"), context)
  const c = new context.Carousel()
  const slides = Array.from({ length: 4 }, (_, id) => ({ id, hidden: false,
    getBoundingClientRect: () => ({ left: 0, top: 0 }),
    animate: () => ({ cancel() {} })
  }))
  const originals = [...slides]
  Object.defineProperty(c, "slideTargets", { get: () => [...slides] })
  c.trackTarget = { append(slide) { slides.splice(slides.indexOf(slide), 1); slides.push(slide) } }
  c.connect()
  assert.equal(active, true)
  assert.equal(delay, 5000)
  for (let step = 0; step < 13; step++) {
    assert.equal(slides[0].id, step % 4)
    assert.equal(slides.length, 4)
    assert.ok(originals.every(slide => slides.includes(slide) && !slide.hidden))
    tick()
  }
  c.disconnect()
  assert.equal(active, false)
})
