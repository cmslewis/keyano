require [
  'static/js/data/KeyCodes'
  'static/js/data/PianoKeys'
  'static/js/instrument/KeyanoInstrument'
  'static/js/listeners/KeyanoDomElementHighlighter'
  'static/js/listeners/KeyanoKeyCombinationNameReporter'
], (
  KeyCodes
  PianoKeys
  KeyanoInstrument
  KeyanoDomElementHighlighter
  KeyanoKeyCombinationNameReporter
) ->


  # Constants
  # =========

  VALID_KEY_NAMES = 'ABCDEFG'.split('')

  LOWEST_KEY_OF_DEFAULT_KEYANO_INSTRUMENT = 'B'

  KEYBOARD_KEYS_FOR_WHITE_PIANO_KEYS = [
    { keyCode : KeyCodes.Q,             label : 'Q' }
    { keyCode : KeyCodes.W,             label : 'W' }
    { keyCode : KeyCodes.E,             label : 'E' }
    { keyCode : KeyCodes.R,             label : 'R' }
    { keyCode : KeyCodes.T,             label : 'T' }
    { keyCode : KeyCodes.Y,             label : 'Y' }
    { keyCode : KeyCodes.U,             label : 'U' }
    { keyCode : KeyCodes.I,             label : 'I' }
    { keyCode : KeyCodes.O,             label : 'O' }
    { keyCode : KeyCodes.P,             label : 'P' }
    { keyCode : KeyCodes.OPEN_BRACKET,  label : '[' }
    { keyCode : KeyCodes.CLOSE_BRACKET, label : ']' }
  ]

  KEYBOARD_KEYS_FOR_BLACK_PIANO_KEY_WRAPPERS = [
    { keyCode : KeyCodes.KEYPAD_2,   label : '2' }
    { keyCode : KeyCodes.KEYPAD_3,   label : '3' }
    { keyCode : KeyCodes.KEYPAD_4,   label : '4' }
    { keyCode : KeyCodes.KEYPAD_5,   label : '5' }
    { keyCode : KeyCodes.KEYPAD_6,   label : '6' }
    { keyCode : KeyCodes.KEYPAD_7,   label : '7' }
    { keyCode : KeyCodes.KEYPAD_8,   label : '8' }
    { keyCode : KeyCodes.KEYPAD_9,   label : '9' }
    { keyCode : KeyCodes.KEYPAD_0,   label : '0' }
    { keyCode : KeyCodes.DASH,       label : '-' }
    { keyCode : KeyCodes.EQUAL_SIGN, label : '=' }
  ]

  KEYBOARD_KEYS_FOR_ALL_PIANO_KEYS = null

  _zipKeys = ({ whiteKeys, blackKeys } = {}) ->
    if not whiteKeys?
      throw new Error 'No whiteKeys passed to _zipKeys'
    if not blackKeys?
      throw new Error 'No blackKeys passed to _zipKeys'

    whiteKeyboardKeys = whiteKeys
    blackKeyboardKeys = blackKeys
    zippedKeys        = []

    numKeys = whiteKeyboardKeys.length + blackKeyboardKeys.length

    for keyIndex in _.range(numKeys)
      isEvenIndex = keyIndex % 2 is 0
      zippedKeys.push(
        if isEvenIndex
          whiteKeyboardKeys[Math.floor(keyIndex / 2)]
        else
          blackKeyboardKeys[Math.floor(keyIndex / 2)]
      )

    return zippedKeys

  # KEY_MAPPINGS = [
  #   { keyCode : KeyCodes.Q,             pianoKey : PianoKeys.A3  }
  #   { keyCode : KeyCodes.KEYPAD_2,      pianoKey : PianoKeys.Bb3 }
  #   { keyCode : KeyCodes.W,             pianoKey : PianoKeys.B3  }
  #   { keyCode : KeyCodes.E,             pianoKey : PianoKeys.C4  }
  #   { keyCode : KeyCodes.KEYPAD_4,      pianoKey : PianoKeys.Db4 }
  #   { keyCode : KeyCodes.R,             pianoKey : PianoKeys.D4  }
  #   { keyCode : KeyCodes.KEYPAD_5,      pianoKey : PianoKeys.Eb4 }
  #   { keyCode : KeyCodes.T,             pianoKey : PianoKeys.E4  }
  #   { keyCode : KeyCodes.Y,             pianoKey : PianoKeys.F4  }
  #   { keyCode : KeyCodes.KEYPAD_7,      pianoKey : PianoKeys.Gb4 }
  #   { keyCode : KeyCodes.U,             pianoKey : PianoKeys.G4  }
  #   { keyCode : KeyCodes.KEYPAD_8,      pianoKey : PianoKeys.Ab4 }
  #   { keyCode : KeyCodes.I,             pianoKey : PianoKeys.A4  }
  #   { keyCode : KeyCodes.KEYPAD_9,      pianoKey : PianoKeys.Bb4 }
  #   { keyCode : KeyCodes.O,             pianoKey : PianoKeys.B4  }
  #   { keyCode : KeyCodes.P,             pianoKey : PianoKeys.C5  }
  #   { keyCode : KeyCodes.DASH,          pianoKey : PianoKeys.Db5 }
  #   { keyCode : KeyCodes.OPEN_BRACKET,  pianoKey : PianoKeys.D5  }
  #   { keyCode : KeyCodes.EQUAL_SIGN,    pianoKey : PianoKeys.Eb5 }
  #   { keyCode : KeyCodes.CLOSE_BRACKET, pianoKey : PianoKeys.E5  }
  # ]

  cachedKeyMappingsForInstrumentWithLowestKey = {}

  $ui =
    keyanoInstruments : $('.KeyanoInstrument')

  _getDomElementForInstrument = (lowestKeyName) ->
    return $ui.keyanoInstruments.filter("[data-lowest-key='#{lowestKeyName}']")

  _getDomElementsForWhiteKeysInInstrument = ($instrument) ->
    return $instrument.find('.KeyanoInstrument-whiteKey')

  _getDomElementsForBlackKeyWrappersInInstrument = ($instrument) ->
    return $instrument.find('.KeyanoInstrument-blackKeyWrapper')

  _getOrderedPianoKeyIdsFromInstrumentDomElement = ($instrument) ->
    $whiteKeys        = _getDomElementsForWhiteKeysInInstrument($instrument)
    $blackKeyWrappers = _getDomElementsForBlackKeyWrappersInInstrument($instrument)

    numKeys            = $whiteKeys.size() + $blackKeyWrappers.size()
    pianoKeyIdsInOrder = []

    for keyIndex in _.range(numKeys)
      isEvenIndex = keyIndex % 2 is 0
      if isEvenIndex
        whiteKeyIndex = Math.floor(keyIndex / 2)
        whiteKeyPianoKeyId = $whiteKeys.eq(whiteKeyIndex).attr('data-piano-key-id')
        pianoKeyIdsInOrder.push(whiteKeyPianoKeyId)
      else
        blackKeyWrapperIndex = Math.floor(keyIndex / 2)
        $blackKey = $blackKeyWrappers.eq(blackKeyWrapperIndex).children('.KeyanoInstrument-blackKey')
        blackKeyPianoKeyId = $blackKey.attr('data-piano-key-id')
        pianoKeyIdsInOrder.push(blackKeyPianoKeyId)

    return pianoKeyIdsInOrder

  _generateKeyMappingsForInstrumentWithLowestKey = (lowestKeyName) ->
    $instrument = _getDomElementForInstrument(lowestKeyName)
    keyMappings = []

    cachedKeyMappings = cachedKeyMappingsForInstrumentWithLowestKey[lowestKeyName]
    if cachedKeyMappings?
      keyMappings = cachedKeyMappings
    else
      pianoKeyIdsInOrder = _getOrderedPianoKeyIdsFromInstrumentDomElement($instrument)
      keyMappings        = _.chain(pianoKeyIdsInOrder)
        .map((pianoKeyId, keyIndex) ->
          result = undefined
          if pianoKeyId?
            result = {
              keyCode  : KEYBOARD_KEYS_FOR_ALL_PIANO_KEYS[keyIndex].keyCode
              pianoKey : PianoKeys[pianoKeyId]
            }
          return result
        )
        .compact()
        .value()
      cachedKeyMappingsForInstrumentWithLowestKey[lowestKeyName] = keyMappings

    return keyMappings

  _showDomElementForKeyanoInstrumentWithLowestKey = (lowestKeyName) ->
    if not _.isString(lowestKeyName)
      throw new Error 'Passed a lowestKeyName to _showKeyanoInstrumentWithLowestKey that was not a string'
    if not lowestKeyName in VALID_KEY_NAMES
      throw new Error 'Passed an invalid lowestKeyName to _showDefaultKeyanoInstrument'

    $ui.keyanoInstruments.hide()
    _getDomElementForInstrument(lowestKeyName).show()

  _populateKeyLabelsInDom = ->
    $ui.keyanoInstruments.each ->
      $instrument = $(this)

      $whiteKeysInOrder        = _getDomElementsForWhiteKeysInInstrument($instrument)
      $blackKeyWrappersInOrder = _getDomElementsForBlackKeyWrappersInInstrument($instrument)

      $whiteKeysInOrder.each (index) ->
        # Every white key contains a label element, so all white-key key codes should appear in the UI after the
        # following operation.
        $label = $(this).find('.KeyanoInstrument-keyLabel')
        $label.text(KEYBOARD_KEYS_FOR_WHITE_PIANO_KEYS[index].label)

      $blackKeyWrappersInOrder.each (index) ->
        # Note that some of these elements wrap "spacers" that will have no label element within them. Setting the
        # .text(...) for these non-existent labels will effectively skip the key code at the current index, which is
        # exactly what we want to happen.
        $label = $(this).find('.KeyanoInstrument-keyLabel')
        $label.text(KEYBOARD_KEYS_FOR_BLACK_PIANO_KEY_WRAPPERS[index].label)

  isLeftKeyPressed             = false
  isRightKeyPressed            = false
  lowestKeyOfCurrentInstrument = null

  $(document).ready ->
    KEYBOARD_KEYS_FOR_ALL_PIANO_KEYS = _zipKeys({
      whiteKeys : KEYBOARD_KEYS_FOR_WHITE_PIANO_KEYS
      blackKeys : KEYBOARD_KEYS_FOR_BLACK_PIANO_KEY_WRAPPERS
    })

    lowestKeyOfCurrentInstrument = LOWEST_KEY_OF_DEFAULT_KEYANO_INSTRUMENT

    _populateKeyLabelsInDom()
    _showDomElementForKeyanoInstrumentWithLowestKey(lowestKeyOfCurrentInstrument)
    keyMappings = _generateKeyMappingsForInstrumentWithLowestKey(lowestKeyOfCurrentInstrument)

    $(document).on 'keydown', (ev) ->
      if isLeftKeyPressed or isRightKeyPressed
        return
      switch ev.keyCode
        when KeyCodes.LEFT_ARROW
          isLeftKeyPressed = true
        when KeyCodes.RIGHT_ARROW
          isRightKeyPressed = true

    $(document).on 'keyup', (ev) ->
      switch ev.keyCode
        when KeyCodes.LEFT_ARROW
          if isLeftKeyPressed
            isLeftKeyPressed = false
        when KeyCodes.RIGHT_ARROW
          if isRightKeyPressed
            isRightKeyPressed = false

    instrument = new KeyanoInstrument()
    instrument.activateKeys(keyMappings)

    new KeyanoDomElementHighlighter({ instrument }).activate()
    new KeyanoKeyCombinationNameReporter({ instrument }).activate()

    return
