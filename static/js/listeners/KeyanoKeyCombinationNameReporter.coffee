define [
  'static/js/listeners/AbstractKeyanoListener'
  'static/js/config/Config'
  'static/js/utils/pianoKeyUtils'
], (
  AbstractKeyanoListener
  Config
  pianoKeyUtils
) ->

  #
  # KeyanoKeyCombinationNameReporter
  # ================================
  # A listener that - when a new piano key starts or stop playing - outputs the name of the currently playing piano-key
  # combination to the UI. This name might be:
  #
  # - the name of a single key (if one key is playing)
  # - the name of an interval (if two keys are playing)
  # - the name of a chord (if three or more keys are playing)
  #

  class KeyanoKeyCombinationNameReporter extends AbstractKeyanoListener


    # Private Constants
    # -----------------

    NAME_LABEL_SELECTOR : '.KeyCombinationNameLabel'


    # Overridden Methods
    # ------------------

    activate : ->
      $outputElem = $(@NAME_LABEL_SELECTOR)

      unless $outputElem?.size() > 0
        throw new Error 'Specified an $outputElem in KeyanoKeyCombinationNameReporter that does not exist in the DOM'

      super

      @$outputElem = $outputElem

      return

    onPianoKeyStartedPlaying : (ev, pianoKeyId) ->
      @_printNameOfKeyCombination()
      return

    onPianoKeyStoppedPlaying : (ev, pianoKeyId) ->
      @_printNameOfKeyCombination()
      return


    # Private Methods
    # ---------------

    _printNameOfKeyCombination : ->
      pianoKeys = @instrument.getImpressedPianoKeys()
      name      = pianoKeyUtils.identifyPianoKeyCombination(pianoKeys)

      @$outputElem?.text(name)
      @$outputElem?.toggleClass 'is-unknown', name is Config.LABEL_FOR_UNRECOGNIZED_CHORDS

      return


  return KeyanoKeyCombinationNameReporter
