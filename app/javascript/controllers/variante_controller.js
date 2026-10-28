  import { Controller } from "@hotwired/stimulus"

   export default class extends Controller {
     static targets = ["preco"]

     atualizar(event) {
       this.precoTarget.textContent = event.target.dataset.precoFormatado
     }
   }