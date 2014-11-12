define [], () ->

  #
  # AbstractKeyanoListener
  # ======================
  # An abstract class that listens for key-started-playing and key-stopped-playing events and fires two respective
  # callbacks that subclasses should override.
  #

  class AbstractKeyanoListener

    ###
    @params
      instrument : (KeyanoInstrument) the keyano instrument firing the events
    ###
    constructor : ({ instrument } = {}) ->
      if not instrument?
        throw new Error 'No instrument provided to AbstractKeyanoListener'

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
