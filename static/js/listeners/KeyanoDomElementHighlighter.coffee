define [
  'static/js/listeners/AbstractKeyanoListener'
], (
  AbstractKeyanoListener
) ->


  class KeyanoDomElementHighlighter extends AbstractKeyanoListener


    # Private Constants
    # -----------------

    DEFAULT_KEYANO_KEY_SELECTOR : '.KeyanoInstrument-key'


    # Instance Variables
    # ------------------

    _domElementCache   : null
    _keyanoKeySelector : null


    # Overridden Methods
    # ------------------

    activate : (keyanoKeys, keyanoKeySelector = @DEFAULT_KEYANO_KEY_SELECTOR) ->
      if not _.isObject(keyanoKeys)
        throw new Error 'Received a missing or invalid keyanoKeys object parameter'
      if not _.isString(keyanoKeySelector)
        throw new Error 'Received a non-string keyanoKeySelector parameter'
      super
      @_domElementCache   = {}
      @_keyanoKeySelector = keyanoKeySelector
      @_fillCacheOfKeyanoKeyDomElements(keyanoKeys)
      return

    onPianoKeyStartedPlaying : (ev, pianoKeyId) ->
      @_domElementCache[pianoKeyId]?.addClass('is-depressed')
      return

    onPianoKeyStoppedPlaying : (ev, pianoKeyId) ->
      @_domElementCache[pianoKeyId]?.removeClass('is-depressed')
      return


    # Private Methods
    # ---------------

    _fillCacheOfKeyanoKeyDomElements : (keyanoKeys) ->
      _.chain(keyanoKeys)
        .pluck('pianoKey')
        .forEach (pianoKey) =>
          $elem = $("#{@_keyanoKeySelector}[data-piano-key-id='#{pianoKey.id}']")
          @_domElementCache[pianoKey.id] = $elem
      return


  return KeyanoDomElementHighlighter
