require [
  'static/js/KeyCodes'
  'static/js/PianoKeys'
  'static/js/KeyanoInstrument'
], (
  KeyCodes
  PianoKeys
  KeyanoInstrument
) ->

  PIANO_KEY_SELECTOR             = '.keyano-key'
  CACHED_KEYANO_KEY_DOM_ELEMENTS = {}
  KEYANO_KEYS                    = [

    # Left Hand

    { keyCode : KeyCodes.Q,        pianoKey : PianoKeys.C4  }
    { keyCode : KeyCodes.KEYPAD_2, pianoKey : PianoKeys.Db4 }
    { keyCode : KeyCodes.W,        pianoKey : PianoKeys.D4  }
    { keyCode : KeyCodes.KEYPAD_3, pianoKey : PianoKeys.Eb4 }
    { keyCode : KeyCodes.E,        pianoKey : PianoKeys.E4  }
    { keyCode : KeyCodes.R,        pianoKey : PianoKeys.F4  }
    { keyCode : KeyCodes.KEYPAD_5, pianoKey : PianoKeys.Gb4 }

    # Right Hand

    { keyCode : KeyCodes.KEYPAD_7, pianoKey : PianoKeys.Gb4 }
    { keyCode : KeyCodes.U,        pianoKey : PianoKeys.G4  }
    { keyCode : KeyCodes.KEYPAD_8, pianoKey : PianoKeys.Ab4 }
    { keyCode : KeyCodes.I,        pianoKey : PianoKeys.A4  }
    { keyCode : KeyCodes.KEYPAD_9, pianoKey : PianoKeys.Bb4 }
    { keyCode : KeyCodes.O,        pianoKey : PianoKeys.B4  }
    { keyCode : KeyCodes.P,        pianoKey : PianoKeys.C5  }

  ]

  _fillCacheOfKeyanoKeyDomElements = (keyanoKeys) ->
    _.chain(keyanoKeys)
      .pluck('pianoKey')
      .forEach (pianoKey) ->
        $elem = $("#{PIANO_KEY_SELECTOR}[data-piano-key-id='#{pianoKey.id}']")
        CACHED_KEYANO_KEY_DOM_ELEMENTS[pianoKey.id] = $elem
    return

  $(document).ready ->
    keyanoInstrument = new KeyanoInstrument()
    keyanoInstrument.activateKeys(KEYANO_KEYS)

    _fillCacheOfKeyanoKeyDomElements(KEYANO_KEYS)

    $(document).on 'piano:key:did:start:playing', (ev, pianoKeyId) ->
      CACHED_KEYANO_KEY_DOM_ELEMENTS[pianoKeyId]?.addClass('depressed')

    $(document).on 'piano:key:did:stop:playing', (ev, pianoKeyId) ->
      CACHED_KEYANO_KEY_DOM_ELEMENTS[pianoKeyId]?.removeClass('depressed')


