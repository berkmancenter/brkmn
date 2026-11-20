import { Controller } from '@hotwired/stimulus'

// Opens and closes the header menu, the Menu button is visible only on small screens
export default class extends Controller {
  static targets = ['toggle']

  toggle() {
    this.setOpen(!this.element.classList.contains('header-items--menu-open'))
  }

  close() {
    this.setOpen(false)
  }

  closeOnOutsideClick(event) {
    if (!this.element.contains(event.target)) {
      this.close()
    }
  }

  setOpen(open) {
    this.element.classList.toggle('header-items--menu-open', open)
    this.toggleTarget.setAttribute('aria-expanded', open)
  }
}
