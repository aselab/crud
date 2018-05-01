import jQuery from 'jquery'
import Rails from 'rails-ujs'

import './crud/modal_picker'
import './crud/crud.scss'

window.$ = window.jQuery = jQuery
window.Rails = Rails
Rails.start()
