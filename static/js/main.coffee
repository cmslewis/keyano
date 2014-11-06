require [
  # General
  'static/js/data/KeyCodes'
  'static/js/data/PianoKeys'
  'static/js/instrument/KeyanoInstrument'
  # Listeners
  'static/js/listeners/KeyanoDomElementHighlighter'
  'static/js/listeners/KeyanoChordTypeReporter'
], (
  # General
  KeyCodes
  PianoKeys
  KeyanoInstrument
  # Listeners
  KeyanoDomElementHighlighter
  KeyanoChordTypeReporter
) ->

  KEYANO_KEYS = [

    # Left Hand

    { keyCode : KeyCodes.Q,             pianoKey : PianoKeys.A3  }
    { keyCode : KeyCodes.KEYPAD_2,      pianoKey : PianoKeys.Bb3 }
    { keyCode : KeyCodes.W,             pianoKey : PianoKeys.B3  }
    { keyCode : KeyCodes.E,             pianoKey : PianoKeys.C4  }
    { keyCode : KeyCodes.KEYPAD_4,      pianoKey : PianoKeys.Db4 }
    { keyCode : KeyCodes.R,             pianoKey : PianoKeys.D4  }
    { keyCode : KeyCodes.KEYPAD_5,      pianoKey : PianoKeys.Eb4 }
    { keyCode : KeyCodes.T,             pianoKey : PianoKeys.E4  }
    { keyCode : KeyCodes.Y,             pianoKey : PianoKeys.F4  }

    # Right Hand

    { keyCode : KeyCodes.KEYPAD_7,      pianoKey : PianoKeys.Gb4 }
    { keyCode : KeyCodes.U,             pianoKey : PianoKeys.G4  }
    { keyCode : KeyCodes.KEYPAD_8,      pianoKey : PianoKeys.Ab4 }
    { keyCode : KeyCodes.I,             pianoKey : PianoKeys.A4  }
    { keyCode : KeyCodes.KEYPAD_9,      pianoKey : PianoKeys.Bb4 }
    { keyCode : KeyCodes.O,             pianoKey : PianoKeys.B4  }
    { keyCode : KeyCodes.P,             pianoKey : PianoKeys.C5  }
    { keyCode : KeyCodes.DASH,          pianoKey : PianoKeys.Db5 }
    { keyCode : KeyCodes.OPEN_BRACKET,  pianoKey : PianoKeys.D5  }
    { keyCode : KeyCodes.EQUAL_SIGN,    pianoKey : PianoKeys.Eb5 }
    { keyCode : KeyCodes.CLOSE_BRACKET, pianoKey : PianoKeys.E5  }

  ]

  $ui =
    chordNameLabel : $('.ChordLabel')

  $(document).ready ->
    keyanoInstrument = new KeyanoInstrument()
    keyanoInstrument.activateKeys(KEYANO_KEYS)

    keyanoDomElementHighlighter = new KeyanoDomElementHighlighter({
      instrument : keyanoInstrument
    }).activate(KEYANO_KEYS)

    keyanoChordTypeReporter = new KeyanoChordTypeReporter({
      instrument : keyanoInstrument
    }).activate(KEYANO_KEYS, $ui.chordNameLabel)

    return

