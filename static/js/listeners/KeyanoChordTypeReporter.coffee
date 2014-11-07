define [
  'static/js/listeners/AbstractKeyanoListener'
  'static/js/config/Config'
  'static/js/utils/pianoKeyUtils'
], (
  AbstractKeyanoListener
  Config
  pianoKeyUtils
) ->


  class KeyanoChordTypeReporter extends AbstractKeyanoListener


    # Instance Variables
    # ------------------

    keyanoKeys : null


    # Overridden Methods
    # ------------------

    activate : (keyanoKeys, $outputElem) ->
      unless $outputElem?.size() > 0
        throw new Error 'Provided an $outputElem in KeyanoChordTypeReporter that does not exist in the DOM'

      super

      @keyanoKeys  = keyanoKeys
      @$outputElem = $outputElem

      return

    onPianoKeyStartedPlaying : (ev, pianoKeyId) ->
      @_printChord()
      return

    onPianoKeyStoppedPlaying : (ev, pianoKeyId) ->
      @_printChord()
      return


    # Private Methods
    # ---------------

    _printChord : ->
      pianoKeys = @instrument.getImpressedPianoKeys()
      name      = pianoKeyUtils.identifyPianoKeyCombination(pianoKeys)

      @$outputElem?.text(name)
      @$outputElem?.toggleClass 'is-unknown', name is Config.LABEL_FOR_UNRECOGNIZED_CHORDS

      return


  return KeyanoChordTypeReporter
