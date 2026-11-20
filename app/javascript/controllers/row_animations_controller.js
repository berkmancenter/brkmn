import { Controller } from '@hotwired/stimulus'

// Shows which row a delete takes away: the row fades out first, the page
// refresh that removes it waits for that. (A changed row comes from the
// server with the url-row--changed class, CSS highlights it.)
export default class extends Controller {
  connect() {
    this.submitStarted = this.submitStarted.bind(this)
    this.submitEnded = this.submitEnded.bind(this)
    this.beforeRender = this.beforeRender.bind(this)
    document.addEventListener('turbo:submit-start', this.submitStarted)
    document.addEventListener('turbo:submit-end', this.submitEnded)
    document.addEventListener('turbo:before-render', this.beforeRender)
  }

  disconnect() {
    document.removeEventListener('turbo:submit-start', this.submitStarted)
    document.removeEventListener('turbo:submit-end', this.submitEnded)
    document.removeEventListener('turbo:before-render', this.beforeRender)
  }

  // A row's Delete link becomes a hidden form with method="delete".
  submitStarted(event) {
    const form = event.target
    if (form.getAttribute('method')?.toLowerCase() !== 'delete') return

    const row = this.rowDeletedBy(form)
    if (!row) return

    row.classList.add('url-row--removing')
    this.removingRow = row
  }

  submitEnded(event) {
    if (event.detail.success || !this.removingRow) return

    this.removingRow.classList.remove('url-row--removing')
    this.removingRow = null
  }

  async beforeRender(event) {
    const row = this.removingRow
    this.removingRow = null
    if (!row?.isConnected) return

    event.preventDefault()
    await this.animationsDone(row)
    event.detail.resume()
  }

  rowDeletedBy(form) {
    const path = new URL(form.action, window.location.href).pathname
    const link = [
      ...this.element.querySelectorAll('tr a[data-turbo-method="delete"]'),
    ].find((candidate) => new URL(candidate.href).pathname === path)
    return link?.closest('tr')
  }

  // The fade out, at most one second.
  animationsDone(row) {
    const animations = row.getAnimations({ subtree: true })
    const finished = Promise.all(
      animations.map((animation) => animation.finished),
    )
    const timeout = new Promise((resolve) => setTimeout(resolve, 1000))
    return Promise.race([finished, timeout]).catch(() => {})
  }
}
