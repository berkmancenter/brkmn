import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  toggle(event) {
    event.preventDefault()

    // Get current mode from data attribute
    const currentMode = this.element.dataset.currentMode

    // Toggle mode
    const newMode = currentMode === 'classic' ? 'modern' : 'classic'

    // Update body classes immediately
    document.body.classList.remove(`viewing-mode-${currentMode}`)
    document.body.classList.add(`viewing-mode-${newMode}`)

    // Update the image and text immediately
    const imageSpan = this.element.querySelector('span:first-child img')
    const textSpan = this.element.querySelector('span:last-child')

    imageSpan.src = newMode === 'classic' ? this.element.dataset.classicImage : this.element.dataset.lightImage
    textSpan.textContent = newMode === 'classic' ? 'Light' : 'Classic'

    // Update the data attribute
    this.element.dataset.currentMode = newMode

    // Make the server request in the background
    fetch(this.element.href, {
      method: 'GET',
    })
  }
}
