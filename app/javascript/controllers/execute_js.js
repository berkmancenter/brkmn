import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  connect() {
    setTimeout(() => {
      [...this.element.children].map(el => this.activateScript(el))
    }, 1)
  }
}
