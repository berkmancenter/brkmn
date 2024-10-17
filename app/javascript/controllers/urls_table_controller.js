import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = []

  copy(event) {
    event.preventDefault()

    // Retrieve the URL from the data attribute
    const urlToCopy = event.currentTarget.dataset.url

    navigator.clipboard
      .writeText(urlToCopy)
      .then(() => {
        alert('URL copied to clipboard!')
      })
      .catch((err) => {
        console.error('Failed to copy text: ', err)
      })
  }
}
