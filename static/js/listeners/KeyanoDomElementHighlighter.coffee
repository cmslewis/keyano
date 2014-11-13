define [
  'static/js/listeners/AbstractKeyanoListener'
  'static/js/data/PianoKeys'
], (
  AbstractKeyanoListener
  PianoKeys
) ->

  #
  # KeyanoDomElementHighlighter
  # ===========================
  # A listener that highlights a particular piano key in the UI whenever its associated pitch starts playing
  # (furthermore, this listener also de-highlights a piano key in the UI when its pitch stops playing).
  #

  class KeyanoDomElementHighlighter extends AbstractKeyanoListener


    # Private Constants
    # -----------------

    KEYANO_KEY_SELECTOR : '.KeyanoInstrument-key'


    # Instance Variables
    # ------------------

    _domElementCache : null


    # Overridden Methods
    # ------------------

    activate : ->
      super

      @_domElementCache = {}

      listOfPianoKeysInOrder = _.map _.pairs(PianoKeys), (pair) -> pair[1]
      @_fillCacheOfKeyanoKeyDomElements(listOfPianoKeysInOrder)

      return

    onPianoKeyStartedPlaying : (ev, pianoKeyId) ->
      @_domElementCache[pianoKeyId]?.addClass('is-depressed')
      return

    onPianoKeyStoppedPlaying : (ev, pianoKeyId) ->
      @_domElementCache[pianoKeyId]?.removeClass('is-depressed')
      return


    # Private Methods
    # ---------------

    _fillCacheOfKeyanoKeyDomElements : (pianoKeys) ->
      _.forEach pianoKeys, (pianoKey) =>
        $elemsWithKeyId = $("#{@KEYANO_KEY_SELECTOR}[data-piano-key-id='#{pianoKey.id}']")
        @_domElementCache[pianoKey.id] = $elemsWithKeyId
      return


  return KeyanoDomElementHighlighter
