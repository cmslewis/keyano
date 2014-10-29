define [], () ->


  class AbstractKeyanoListener

    ###
    @params
      instrument : (KeyanoInstrument) the keyano instrument firing the events
    ###
    constructor : ({ instrument }) ->
      @instrument = instrument

    activate : ->
      $(document).on 'piano:key:did:start:playing', (ev, pianoKeyId) =>
        @onPianoKeyStartedPlaying(ev, pianoKeyId)
      $(document).on 'piano:key:did:stop:playing',  (ev, pianoKeyId) =>
        @onPianoKeyStoppedPlaying(ev, pianoKeyId)
      return

    onPianoKeyStartedPlaying : (ev, pianoKeyId) ->
      throw new Error 'not implemented'

    onPianoKeyStoppedPlaying : ->
      throw new Error 'not implemented'


  return AbstractKeyanoListener
