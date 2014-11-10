require [
  'static/js/KeyanoApplication'
], (
  KeyanoApplication
) ->

  $(document).ready ->
    new KeyanoApplication().start()
