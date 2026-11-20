import { Controller } from '@hotwired/stimulus'
import { Turbo } from '@hotwired/turbo-rails'

// A link whose answer is a Turbo Stream (for example a dialog to show), loaded
// without leaving the page. Without JavaScript, or with Ctrl/Cmd click, the
// link opens its normal page.
export default class extends Controller {
  async load(event) {
    if (event.button !== 0 || event.metaKey || event.ctrlKey || event.shiftKey)
      return

    event.preventDefault()
    if (this.loading) return

    this.loading = true
    try {
      const response = await fetch(this.element.href, {
        headers: { Accept: 'text/vnd.turbo-stream.html' },
      })

      // Signed out, no permission, or an error: show the normal page instead.
      if (response.redirected || !response.ok) {
        window.location.assign(this.element.href)
        return
      }

      Turbo.renderStreamMessage(await response.text())
    } catch (error) {
      console.error('Failed to load', this.element.href, error)
      window.location.assign(this.element.href)
    } finally {
      this.loading = false
    }
  }
}
