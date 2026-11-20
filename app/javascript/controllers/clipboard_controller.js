import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['source', 'button']

  async copy() {
    try {
      await navigator.clipboard.writeText(this.sourceTarget.textContent.trim())
      this.buttonTarget.textContent = 'Copied'
    } catch (error) {
      console.error('Failed to copy text: ', error)
      this.buttonTarget.textContent = 'Select and copy manually'
    }
  }
}
