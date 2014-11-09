require [
  'static/js/data/KeyCodes'
  'static/js/data/PianoKeys'
  'static/js/instrument/KeyanoInstrument'
  'static/js/listeners/KeyanoDomElementHighlighter'
  'static/js/listeners/KeyanoKeyCombinationNameReporter'
  'static/js/utils/pianoKeyUtils'
  'static/js/config/Config'
], (
  KeyCodes
  PianoKeys
  KeyanoInstrument
  KeyanoDomElementHighlighter
  KeyanoKeyCombinationNameReporter
  pianoKeyUtils
  Config
) ->


  # Constants
  # =========

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

  _zipKeyArrays = ({ whiteKeys, blackKeys } = {}) ->
    if not whiteKeys?
      throw new Error 'No whiteKeys passed to _zipKeyArrays'
    if not blackKeys?
      throw new Error 'No blackKeys passed to _zipKeyArrays'

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
    keyboards                : $('.KeyanoInstrument-keyboard')
    keyboardLeftShiftButton  : $('.KeyboardShiftButton-leftButton')
    keyboardRightShiftButton : $('.KeyboardShiftButton-rightButton')

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
    if not pianoKeyUtils.isValidWhiteKeyName(lowestKeyName)
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
        pianoKeyId = $(this).attr('data-piano-key-id')
        $label     = $(this).find('.KeyanoInstrument-keyLabel')
        $name      = $(this).find('.KeyanoInstrument-whiteKeyNameLabel')
        $label.text(KEYBOARD_KEYS_FOR_WHITE_PIANO_KEYS[index].label)
        $name.text(pianoKeyId)

      $blackKeyWrappersInOrder.each (index) ->
        # Note that some of these elements wrap "spacers" that will have no label element within them. Setting the
        # .text(...) for these non-existent labels will effectively skip the key code at the current index, which is
        # exactly what we want to happen.
        pianoKeyId = $(this).find('[data-piano-key-id]').attr('data-piano-key-id')
        $label     = $(this).find('.KeyanoInstrument-keyLabel')
        $name      = $(this).find('.KeyanoInstrument-blackKeyNameLabel')
        $label.text(KEYBOARD_KEYS_FOR_BLACK_PIANO_KEY_WRAPPERS[index].label)
        $name.text(pianoKeyId)

  _shiftKeyboardToHaveLowestKey = (instrument, lowestKeyName) ->
    lowestKeyOfCurrentKeyboardRange = lowestKeyName
    _showDomElementForKeyanoInstrumentWithLowestKey(lowestKeyName)
    keyMappings = _generateKeyMappingsForInstrumentWithLowestKey(lowestKeyName)
    instrument.activateKeys(keyMappings)

  _shiftKeyboardDownward = (instrument) ->
    previousKeyName = pianoKeyUtils.getKeyNameOfNextLowestWhiteKey(lowestKeyOfCurrentKeyboardRange)
    _shiftKeyboardToHaveLowestKey(instrument, previousKeyName)

  _shiftKeyboardUpward = (instrument) ->
    nextKeyName = pianoKeyUtils.getKeyNameOfNextHighestWhiteKey(lowestKeyOfCurrentKeyboardRange)
    _shiftKeyboardToHaveLowestKey(instrument, nextKeyName)

  _activateKeyboardSwitching = ({ instrument, downwardKeyCodes, upwardKeyCodes } = {}) ->
    # Have an unthrottled keydown listener to prevent default behavior of special keys (tab, escape, etc).
    $(document).on 'keydown', (ev) ->
      if ev.keyCode in downwardKeyCodes or ev.keyCode in upwardKeyCodes
        ev.stopPropagation()
        ev.preventDefault()

    selectedClass = 'KeyboardShiftButton--selected'

    TRANSITION_END_EVENTS = '''
      transitionend
      webkitTransitionEnd
      oTransitionEnd
      otransitionend
      MSTransitionEnd
    '''

    flashSelectedState = ($button) ->
      if not $button.is(':hover')
        $button.on TRANSITION_END_EVENTS, ->
          $button.removeClass(selectedClass)
        .addClass(selectedClass)

    # Have a throttled keydown listener to actually trigger keyboard shift operations.
    $(document).on 'keydown', _.throttle (ev) ->
      if ev.keyCode in downwardKeyCodes
        _shiftKeyboardDownward(instrument)
        flashSelectedState($ui.keyboardLeftShiftButton)
      if ev.keyCode in upwardKeyCodes
        _shiftKeyboardUpward(instrument)
        flashSelectedState($ui.keyboardRightShiftButton)
    , Config.KEYBOARD_SHIFT_THROTTLE_LIMIT_IN_MILLIS

    $ui.keyboardLeftShiftButton.on  'click', -> _shiftKeyboardDownward(instrument)
    $ui.keyboardRightShiftButton.on 'click', -> _shiftKeyboardUpward(instrument)

  _activateTooltips = ->
    defaultOptions = {
      show :
        delay  : 50
        effect : false
      hide :
        effect : false
      style :
        classes : 'KeyboardShiftButton-tooltip'
    }

    leftButtonOptions = _.defaults {
      position :
        my : 'left center'
        at : 'right center'
      content :
        text : '''
          <div class="KeyboardShiftButton-tooltipMain">Shift Keyboard Down</div>
          <div class="KeyboardShiftButton-tooltipSecondary">
            (Shortcut: Tab or Left Arrow Keys)
          </div>
        '''
    }, defaultOptions

    rightButtonOptions = _.defaults {
      position :
        my : 'right center'
        at : 'left center'
      content :
        text : '''
          <div class="KeyboardShiftButton-tooltipMain">Shift Keyboard Up</div>
          <div class="KeyboardShiftButton-tooltipSecondary">
            (Shortcut: \\ or Right Arrow Keys)
          </div>
        '''
    }, defaultOptions

    $ui.keyboardLeftShiftButton.qtip(leftButtonOptions)
    $ui.keyboardRightShiftButton.qtip(rightButtonOptions)

  $(document).ready ->
    KEYBOARD_KEYS_FOR_ALL_PIANO_KEYS = _zipKeyArrays({
      whiteKeys : KEYBOARD_KEYS_FOR_WHITE_PIANO_KEYS
      blackKeys : KEYBOARD_KEYS_FOR_BLACK_PIANO_KEY_WRAPPERS
    })

    instrument = new KeyanoInstrument()

    new KeyanoDomElementHighlighter({ instrument }).activate()
    new KeyanoKeyCombinationNameReporter({ instrument }).activate()

    _activateTooltips()
    _activateKeyboardSwitching({
      instrument       : instrument
      downwardKeyCodes : Config.KEYBOARD_SHIFT_DOWNWARD_KEY_CODES
      upwardKeyCodes   : Config.KEYBOARD_SHIFT_UPWARD_KEY_CODES
    })
    _populateKeyLabelsInDom()
    _shiftKeyboardToHaveLowestKey(instrument, LOWEST_KEY_OF_DEFAULT_KEYBOARD_RANGE)

    return
