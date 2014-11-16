define [
  'static/js/instrument/KeyanoInstrument'
  'static/js/listeners/KeyanoDomElementHighlighter'
  'static/js/listeners/KeyanoKeyCombinationNameReporter'
  'static/js/KeyanoView'
], (
  KeyanoInstrument
  KeyanoDomElementHighlighter
  KeyanoKeyCombinationNameReporter
  KeyanoView
) ->

  class KeyanoFailureView

    ui :
      loadingSpinnerOverlay : $('.LoadingSpinner-overlay')
      failureMessageOverlay : $('.FailureMessage-overlay')

    activate : ->
      @ui.loadingSpinnerOverlay.hide()
      @ui.failureMessageOverlay.show()


  #
  # KeyanoApplication
  # =================
  # This is the starting point for initializing the entire application.
  #
  class KeyanoApplication

    start : ->

      if not AudioContext? and not webkitAudioContext?
        new KeyanoFailureView().activate()
        return

      # Instrument

      instrument = new KeyanoInstrument()

      # Instrument Listeners

      new KeyanoDomElementHighlighter({ instrument }).activate()
      new KeyanoKeyCombinationNameReporter({ instrument }).activate()

      # View

      new KeyanoView({ instrument }).activate()


  return KeyanoApplication
