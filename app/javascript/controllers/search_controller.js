import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  toggle() {
    const url = window.location.href
    const urlObj = new URL(url)
    const searchParams = new URLSearchParams(urlObj.search)
    const searchValue = searchParams.get('search')

    if (!searchValue) {
      document.querySelector('.search').classList.toggle('header-items-item-search-active')

      // Focus on the search input
      setTimeout(() => {
        if (document.querySelector('.search').classList.contains('header-items-item-search-active')) {
          document.querySelector('#search').focus()
        }
      }, 350)
    }
  }
}
