define [
  'static/js/listeners/AbstractKeyanoListener'
], (
  AbstractKeyanoListener
) ->


  class KeyanoChordTypeReporter extends AbstractKeyanoListener


    # Instance Variables
    # ------------------

    keyanoKeys : null


    # Overridden Methods
    # ------------------

    activate : (keyanoKeys) ->
      @keyanoKeys = keyanoKeys
      super

    onPianoKeyStartedPlaying : (ev, pianoKeyId) ->
      @_printChord()
      return

    onPianoKeyStoppedPlaying : (ev, pianoKeyId) ->
      @_printChord()
      return


    # Private Methods
    # ---------------

    _printChord : ->
      impressedPianoKeys = @instrument.getImpressedPianoKeys()
      chord = @_identifyChord(impressedPianoKeys)
      console.log chord

    ###
    Returns the name of the chord indicated by the provided piano key combination.
    @params
      pianoKeys : [
        <pianoKeyId> (string),
        ...
      ]
    @return
      (string) the name of the chord (e.g. CM7)
    ###
    _identifyChord : (pianoKeys) ->
      console.log pianoKeys
      # sort the piano keys in order on the piano
      return 'CM7'


  return KeyanoChordTypeReporter
