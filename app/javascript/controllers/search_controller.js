import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  toggle() {
    document.querySelector('.search').classList.toggle('header-items-item-search-active')
  }
}
