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

  KEYBOARD_SHIFT_THROTTLE_LIMIT_IN_MILLIS = 500

  LOWEST_KEY_OF_DEFAULT_KEYBOARD_RANGE = 'C'

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

  isLeftKeyPressed                            = false
  isRightKeyPressed                           = false
  lowestKeyOfCurrentKeyboardRange             = null
  cachedKeyMappingsForInstrumentWithLowestKey = {}

  $ui =
    keyboards : $('.KeyanoInstrument-keyboard')

  _getDomElementForInstrument = (lowestKeyName) ->
    return $ui.keyboards.filter("[data-lowest-key='#{lowestKeyName}']")

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

  _getNextWhiteKeyName = (keyName) ->
    if not keyName in VALID_KEY_NAMES
      throw new Error "Invalid keyName #{keyName}"

    if keyName is _.last(VALID_KEY_NAMES)
      higherKeyIndex = 0
    else
      higherKeyIndex = VALID_KEY_NAMES.indexOf(keyName) + 1

    return VALID_KEY_NAMES[higherKeyIndex]

  _getPreviousWhiteKeyName = (keyName) ->
    if not keyName in VALID_KEY_NAMES
      throw new Error "Invalid keyName #{keyName}"

    if keyName is _.first(VALID_KEY_NAMES)
      lowerKeyIndex = VALID_KEY_NAMES.length - 1
    else
      lowerKeyIndex = VALID_KEY_NAMES.indexOf(keyName) - 1

    return VALID_KEY_NAMES[lowerKeyIndex]

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

    $ui.keyboards.hide()
    _getDomElementForInstrument(lowestKeyName).show()

  _populateKeyLabelsInDom = ->
    $ui.keyboards.each ->
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

  _shiftKeyboardToHaveLowestKey = (instrument, lowestKeyName) ->
    lowestKeyOfCurrentKeyboardRange = lowestKeyName
    _showDomElementForKeyanoInstrumentWithLowestKey(lowestKeyName)
    keyMappings = _generateKeyMappingsForInstrumentWithLowestKey(lowestKeyName)
    instrument.activateKeys(keyMappings)

  _shiftKeyboardDownward = (instrument) ->
    previousKeyName = _getPreviousWhiteKeyName(lowestKeyOfCurrentKeyboardRange)
    _shiftKeyboardToHaveLowestKey(instrument, previousKeyName)

  _shiftKeyboardUpward = (instrument) ->
    nextKeyName = _getNextWhiteKeyName(lowestKeyOfCurrentKeyboardRange)
    _shiftKeyboardToHaveLowestKey(instrument, nextKeyName)

  $(document).ready ->
    KEYBOARD_KEYS_FOR_ALL_PIANO_KEYS = _zipKeys({
      whiteKeys : KEYBOARD_KEYS_FOR_WHITE_PIANO_KEYS
      blackKeys : KEYBOARD_KEYS_FOR_BLACK_PIANO_KEY_WRAPPERS
    })

    instrument = new KeyanoInstrument()

    $(document).on 'keydown', _.throttle (ev) ->
      switch ev.keyCode
        when KeyCodes.LEFT_ARROW  then _shiftKeyboardDownward(instrument)
        when KeyCodes.RIGHT_ARROW then _shiftKeyboardUpward(instrument)
    , KEYBOARD_SHIFT_THROTTLE_LIMIT_IN_MILLIS

    new KeyanoDomElementHighlighter({ instrument }).activate()
    new KeyanoKeyCombinationNameReporter({ instrument }).activate()

    _populateKeyLabelsInDom()
    _shiftKeyboardToHaveLowestKey(instrument, LOWEST_KEY_OF_DEFAULT_KEYBOARD_RANGE)

    return
