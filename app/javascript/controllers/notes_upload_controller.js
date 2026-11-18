import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["picker", "names", "rows", "status"]
  static values = { level: String }

  connect() { this.previews = new Set() }

  disconnect() { this.previews.forEach(url => URL.revokeObjectURL(url)) }

  names() {
    return this.namesTarget.value.split(/[,;\n]+/).map(name => name.trim()).filter(Boolean)
  }

  addFiles() {
    const names = this.names()
    const rows = Array.from(this.rowsTarget.querySelectorAll("[data-new-note]"))
    const withoutPhotos = rows.filter(row => !row.querySelector('input[type="file"]')?.files.length)
    const offset = rows.length
    let added = 0
    let rejected = 0
    Array.from(this.pickerTarget.files).forEach(file => {
      if (!["image/jpeg", "image/png", "image/webp"].includes(file.type) || file.size > 5 * 1024 * 1024) {
        rejected += 1
        return
      }
      const name = names[offset + added] || file.name.replace(/\.[^.]+$/, "").replace(/[_-]+/g, " ").trim()
      const row = withoutPhotos.shift()
      if (row) {
        const nameInput = row.querySelector('input[type="text"]')
        if (!nameInput.value.trim()) nameInput.value = name.slice(0, 80)
        this.attachImage(row, file)
      } else this.addRow(name, file)
      added += 1
    })
    this.pickerTarget.value = ""
    this.statusTarget.textContent = `${added} foto(s) adicionada(s).${rejected ? ` ${rejected} arquivo(s) recusado(s): use JPG, PNG ou WebP de até 5 MB.` : " Confira os nomes e salve o produto."}`
  }

  applyNames() {
    const names = this.names()
    if (!names.length) {
      this.statusTarget.textContent = "Informe os nomes separados por vírgula ou por linha."
      return
    }
    const rows = Array.from(this.rowsTarget.querySelectorAll("[data-new-note]"))
    names.forEach((name, index) => {
      if (rows[index]) rows[index].querySelector('input[type="text"]').value = name
      else this.addRow(name)
    })
    this.statusTarget.textContent = `${names.length} nome(s) aplicado(s). Confira a seleção e salve o produto.`
  }

  addRow(name, file = null) {
    // Rails expects numeric indexes when permitting nested attributes.
    const key = BigInt(`0x${crypto.randomUUID().replaceAll("-", "")}`).toString()
    const id = `note_${this.levelValue}_${key}`
    const prefix = `produto[notas_olfativas_attributes][${key}]`
    const row = document.createElement("div")
    row.className = "notes-upload-card"
    row.dataset.newNote = "true"
    const level = document.createElement("input")
    Object.assign(level, { type: "hidden", name: `${prefix}[nivel]`, value: this.levelValue })
    row.append(level)
    const placeholder = document.createElement("span")
    placeholder.className = "notes-upload-placeholder material-symbols-outlined"
    placeholder.textContent = "eco"
    placeholder.setAttribute("aria-hidden", "true")
    row.append(placeholder)
    const label = document.createElement("label")
    label.htmlFor = id
    label.textContent = "Nome da nota"
    const input = document.createElement("input")
    Object.assign(input, { id, type: "text", name: `${prefix}[nome]`, value: name.slice(0, 80), maxLength: 80, required: true })
    const remove = document.createElement("button")
    Object.assign(remove, { type: "button", textContent: "Remover da seleção", className: "notes-upload-remove-button" })
    remove.addEventListener("click", event => this.removeRow(event))
    row.append(label, input, remove)
    if (file) this.attachImage(row, file)
    this.rowsTarget.append(row)
  }

  removeRow(event) {
    const row = event.currentTarget.closest(".notes-upload-card")
    const url = row.dataset.previewUrl
    if (url) { URL.revokeObjectURL(url); this.previews.delete(url) }
    row.remove()
    this.statusTarget.textContent = "Nota removida da seleção."
  }

  attachImage(row, file) {
    const url = URL.createObjectURL(file)
    this.previews.add(url)
    row.dataset.previewUrl = url
    const image = document.createElement("img")
    Object.assign(image, { src: url, alt: file.name, className: "notes-upload-preview" })
    row.querySelector(".notes-upload-placeholder, .notes-upload-preview").replaceWith(image)
    const previous = row.querySelector('input[type="file"]')
    const input = previous || document.createElement("input")
    const level = row.querySelector('input[type="hidden"]')
    Object.assign(input, { type: "file", name: level.name.replace(/\[nivel\]$/, "[imagem]"), hidden: !previous })
    const transfer = new DataTransfer()
    transfer.items.add(file)
    input.files = transfer.files
    row.append(input)
  }

}
