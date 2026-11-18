import { test } from "node:test"
import assert from "node:assert/strict"
import { readFileSync } from "node:fs"
import vm from "node:vm"

test("galeria troca a foto ampliada e identifica a miniatura selecionada", () => {
  const fonte = readFileSync(new URL("../../app/javascript/controllers/product_gallery_controller.js", import.meta.url), "utf8")
  const contexto = vm.createContext({ Controller: class {} })
  vm.runInContext(fonte.replace(/^import .*\n/, "").replace("export default class", "globalThis.Classe = class"), contexto)
  const c = new contexto.Classe()
  const miniatura = (url) => ({ dataset: { imageUrl: url, imageAlt: "Perfume" }, setAttribute(chave, valor) { this[chave] = valor } })
  const primeira = miniatura("/foto-1.png")
  const segunda = miniatura("/foto-2.png")
  c.imageTarget = { src: "/foto-1.png", alt: "" }
  c.linkTarget = { href: "/foto-1.png" }
  c.thumbnailTargets = [primeira, segunda]
  c.select({ currentTarget: segunda })
  assert.equal(c.imageTarget.src, "/foto-2.png")
  assert.equal(c.imageTarget.alt, "Perfume")
  assert.equal(c.linkTarget.href, "/foto-2.png")
  assert.equal(primeira["aria-pressed"], "false")
  assert.equal(segunda["aria-pressed"], "true")
})
