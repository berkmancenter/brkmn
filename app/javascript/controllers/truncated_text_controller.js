import { Controller } from '@hotwired/stimulus'

// Long text is cut with "…" by CSS, then a button shows next to it.
// The button shows the whole text and makes it short again.
export default class extends Controller {
  static targets = ['text', 'toggle']
  static classes = ['expanded']

  connect() {
    // Fires also right after observe, so the button is correct from the start
    this.observer = new ResizeObserver(() => this.update())
    this.observer.observe(this.textTarget)
  }

  disconnect() {
    this.observer.disconnect()
  }

  toggle() {
    const expanded = !this.element.classList.contains(this.expandedClass)

    this.element.classList.toggle(this.expandedClass, expanded)
    this.toggleTarget.setAttribute('aria-expanded', expanded)
  }

  update() {
    // Expanded text is not cut, but the button must stay to make it short again
    if (this.element.classList.contains(this.expandedClass)) return

    this.toggleTarget.hidden = this.textTarget.scrollWidth <= this.textTarget.clientWidth
  }
}
