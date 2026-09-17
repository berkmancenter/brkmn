import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['dialog', 'feedback']
  static values = { autoOpen: Boolean, detailsUrl: String }

  connect() {
    if (this.autoOpenValue && !this.dialogTarget.open)
      this.dialogTarget.showModal()
  }

  async open(event) {
    event.preventDefault()
    if (this.loading) return

    this.loading = true
    let dialog = this.dialogTarget

    try {
      const response = await fetch(this.detailsUrlValue, {
        headers: { Accept: 'text/html' },
      })

      if (response.redirected) {
        window.location.assign(response.url)
        return
      }

      if (!response.ok)
        throw new Error(`Request failed with status ${response.status}`)

      const template = document.createElement('template')
      template.innerHTML = await response.text()
      const reloadedDialog = template.content.querySelector('dialog')

      if (!reloadedDialog)
        throw new Error('The response did not include a dialog')

      dialog.replaceWith(reloadedDialog)
      dialog = reloadedDialog
    } catch (error) {
      console.error('Failed to reload link details:', error)
    } finally {
      this.loading = false
    }

    if (dialog.isConnected && !dialog.open) dialog.showModal()
  }

  close() {
    this.dialogTarget.close()
  }

  clearFeedback() {
    if (this.hasFeedbackTarget) this.feedbackTarget.replaceChildren()
    this.autoOpenValue = false
  }

  clearShareForm(event) {
    if (event.detail.success) event.currentTarget.reset()
  }

  close_on_backdrop(event) {
    if (event.target === this.dialogTarget) this.close()
  }
}
