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
      impressedPianoKeyIds = @instrument.getImpressedPianoKeyIds()
      chord = @_identifyChord(impressedPianoKeyIds)
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
    _identifyChord : (pianoKeyIds) ->
      console.log pianoKeyIds
      # sort the piano keys in order on the piano
      return 'CM7'


  return KeyanoChordTypeReporter
