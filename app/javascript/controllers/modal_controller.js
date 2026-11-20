import { Controller } from '@hotwired/stimulus'

// A <dialog> that opens when it is added to the page and removes itself when
// it is closed (×, Cancel, Escape or a click on the backdrop), so the next
// open loads it fresh.
export default class extends Controller {
  connect() {
    if (!this.element.open) this.element.showModal()
    this.#cursorToEnd()
  }

  close() {
    this.element.close()
  }

  closeOnBackdrop(event) {
    if (event.target === this.element) this.close()
  }

  remove() {
    this.element.remove()
  }

  // showModal focuses the autofocus field with the cursor at the start. Put
  // it at the end of the text (and show the end of a long value), so typing
  // continues what is there.
  #cursorToEnd() {
    const field = this.element.querySelector('[autofocus]')
    if (!field || typeof field.setSelectionRange !== 'function') return

    const end = field.value.length
    field.focus()
    field.setSelectionRange(end, end)
    field.scrollLeft = field.scrollWidth
  }
}
