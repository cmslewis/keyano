define [
  'static/js/data/KeyCodes'
  'static/js/data/PianoKeys'
  'static/js/instrument/KeyanoInstrument'
  'static/js/utils/pianoKeyUtils'
  'static/js/config/Config'
], (
  KeyCodes
  PianoKeys
  KeyanoInstrument
  pianoKeyUtils
  Config
) ->

  #
  # KeyanoView
  # ==========
  # Populates and activates interactive elements in the DOM.
  #
  class KeyanoView


    # Constants
    # ---------

    KEYBOARD_KEYS_FOR_WHITE_PIANO_KEYS : [
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

    KEYBOARD_KEYS_FOR_BLACK_PIANO_KEY_WRAPPERS : [
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

    DEFAULT_BUTTON_TOOLTIP_OPTIONS : {
      show :
        delay  : 50
        effect : false
      hide :
        effect : false
      style :
        classes : 'KeyboardShiftButton-tooltip'
    }

    DEFAULT_SLIDER_OPTIONS : {
      # Options used by the bootstrap-slider plugin.
      min         : 0
      max         : 100
      step        : 1
      value       : 100
      orientation : 'vertical'
      reversed    : true
      tooltip     : 'hide'

      # Options used only internally.
      nLogSteps : 3
    }

    VOLUME_VALUE_LOCAL_STORAGE_KEY : 'keyano-volume-value'

    SLIDER_VALUE_LOCAL_STORAGE_KEY : 'keyano-volume-slider-value'


    # Instance Variables
    # ------------------

    _cachedKeyMappingsForKeyboardWithLowestKey : {}
    _lowestKeyOfCurrentKeyboardRange             : null
    _instrument                                  : null


    # Marionette Mimicry
    # ------------------

    ui :
      loadingSpinnerOverlay       : $('.LoadingSpinner-overlay')
      instrument                  : $('.KeyanoInstrument')
      keyboards                   : $('.KeyanoInstrument-keyboard')
      keyboardLeftShiftButton     : $('.KeyboardShiftButton-leftButton')
      keyboardRightShiftButton    : $('.KeyboardShiftButton-rightButton')
      masterVolumeSlider          : $('.KeyanoInstrument-masterVolumeSlider')
      masterVolumeDropdownTrigger : $('.Header-dropdownTrigger')
      masterVolumeDropdownWrapper : $('.Header-dropdown')


    # Public Methods
    # --------------

    constructor : ({ instrument } = {}) ->
      if not instrument?
        throw new Error 'No instrument parameter provided'
      if not instrument instanceof KeyanoInstrument
        throw new Error 'Invalid instrument parameter provided'

      @_instrument = instrument

      @KEYBOARD_KEYS_FOR_ALL_PIANO_KEYS = @_zipKeyMappingArrays({
        whiteKeys : @KEYBOARD_KEYS_FOR_WHITE_PIANO_KEYS
        blackKeys : @KEYBOARD_KEYS_FOR_BLACK_PIANO_KEY_WRAPPERS
      })

    activate : ->
      @_populatePianoKeyLabelsInDom()
      @_activateMasterVolumeSlider()
      @_activateKeyboardShiftButtonTooltips()
      @_activateKeyboardShiftTriggers({
        instrument       : @_instrument
        downwardKeyCodes : Config.KEYBOARD_SHIFT_DOWNWARD_KEY_CODES
        upwardKeyCodes   : Config.KEYBOARD_SHIFT_UPWARD_KEY_CODES
      })
      @_shiftKeyboardToHaveLowestKey(@_instrument, Config.LOWEST_KEY_OF_DEFAULT_KEYBOARD_RANGE)

      @ui.instrument.show()
      @ui.loadingSpinnerOverlay.addClass('LoadingSpinner-overlay--hidden')


    # Private Methods (Activation)
    # ----------------------------

    _activateMasterVolumeSlider : ->
      @ui.masterVolumeDropdownTrigger.on 'click', =>
        @ui.masterVolumeDropdownWrapper.toggleClass('open')

      $(document).on 'click', (ev) =>
        isDropdownOpen               = @ui.masterVolumeDropdownWrapper.hasClass('open')
        isClickWithinDropdownWrapper = $(ev.target).closest('.Header-dropdown').size() > 0

        if isDropdownOpen and not isClickWithinDropdownWrapper
          @ui.masterVolumeDropdownWrapper.removeClass('open')

      sliderOptions = @DEFAULT_SLIDER_OPTIONS

      # Try to use the volume value from this user's previous visit.

      savedVolumeValue = @_getSavedVolumeValue()
      if _.isNumber(savedVolumeValue) and _.isFinite(savedVolumeValue)
        sliderOptions = _.defaults({
          value : @_getSavedVolumeSliderValue()
        }, sliderOptions)
        @_instrument.setVolume(savedVolumeValue)

      # Initialize the slider, saving both raw slider and computed volume values in localStorage on every change.

      @ui.masterVolumeSlider.slider(sliderOptions)
        .on('change', (ev) =>
          newSliderValue = ev.value.newValue
          newVolume      = @_mapSliderValueToVolumeValue(ev.value.newValue)

          @_setSavedVolumeSliderValue(newSliderValue)
          @_setSavedVolumeValue(newVolume)

          @_instrument.setVolume(newVolume)
        )

    _mapSliderValueToVolumeValue : (newSliderValue) ->

      # The slider will be logarithmic, mapping slider values to volume values as follows:
      #
      #   volume = 10 ^ (-1 * (nLogSteps - ((sliderValue / 100) * nLogSteps)))
      #
      # where
      #   - volume is the final volume value in [0, 1]
      #   - sliderValue is the raw slider value in [0, 100]
      #   - nOrdersOfMagnitude is the number of order-of-magnitude jumps to fit evenly between 0 and 100.
      #     For instance,
      #        if nLogSteps = 2, then 100 => 10^0, and 50 => 10^(-1)
      #        if nLogSteps = 3, then 100 => 10^0, 66 => 10^(-1), and 33 => 10^(-2)
      #        if nLogSteps = 4, then 100 => 10^0, 75 => 10^(-1), 50 => 10^(-2), and 25 => 10^(-3)
      #     and so on.
      #
      # As a special case, 0 will always map to 0.

      if newSliderValue is 0
        return 0
      else
        maxValue  = @DEFAULT_SLIDER_OPTIONS.max
        nLogSteps = @DEFAULT_SLIDER_OPTIONS.nLogSteps
        exponent  = -1 * (nLogSteps - ((newSliderValue / maxValue) * nLogSteps))
        return Math.pow(10, exponent)

    _activateKeyboardShiftButtonTooltips : ->
      # Activate the left-side keyboard-shift button.
      @ui.keyboardLeftShiftButton.qtip(_.defaults {
        position :
          my : 'left center'
          at : 'right center'
        content :
          text : '''
            <div class="KeyboardShiftButton-tooltipMain">Shift Keyboard Down</div>
            <div class="KeyboardShiftButton-tooltipSecondary">
              (Shortcut: Tab or Left Arrow Key)
            </div>
          '''
      }, @DEFAULT_BUTTON_TOOLTIP_OPTIONS)

      # Activate the right-side keyboard-shift button.
      @ui.keyboardRightShiftButton.qtip(_.defaults {
        position :
          my : 'right center'
          at : 'left center'
        content :
          text : '''
            <div class="KeyboardShiftButton-tooltipMain">Shift Keyboard Up</div>
            <div class="KeyboardShiftButton-tooltipSecondary">
              (Shortcut: \\ or Right Arrow Key)
            </div>
          '''
      }, @DEFAULT_BUTTON_TOOLTIP_OPTIONS)

    _activateKeyboardShiftTriggers : ({ instrument, downwardKeyCodes, upwardKeyCodes } = {}) ->
      selectedClass = 'KeyboardShiftButton--selected'

      # Define a couple little helpers that will be used only within this function scope.

      flashButtonSelectedState = ($button) ->
        if $button.is(':hover')
          return
        $button.addClass(selectedClass)
          .delay(150)
          .queue(->
            $(this).removeClass(selectedClass)
            $(this).dequeue();
          )

      verifyKeyCodesAreUnused = =>
        shiftOperationKeyCodes = _.flatten([downwardKeyCodes, upwardKeyCodes])
        for shiftOperationKeyCode in shiftOperationKeyCodes
          _.forEach @KEYBOARD_KEYS_FOR_ALL_PIANO_KEYS, (keyMapping) ->
            if keyMapping.keyCode is shiftOperationKeyCode
              throw new Error 'Tried to map a piano keyboard key to also trigger a keyboard-shift operation.'

      verifyKeyCodesAreUnused()

      # Allow the user to shift the keyboard by pressing particular keys. Define this throttled event listener so
      # that the user can't trigger successive keyboard shifts too quickly (the shift operation takes a non-trivial
      # amount of work the first time each keyboard variant is shown, so we want to give the operation time to finish
      # before being asked to execute again).

      $(document).on 'keydown', _.throttle (ev) =>

        if ev.keyCode in downwardKeyCodes
          @_shiftKeyboardDownward(instrument)
          flashButtonSelectedState(@ui.keyboardLeftShiftButton)

        if ev.keyCode in upwardKeyCodes
          @_shiftKeyboardUpward(instrument)
          flashButtonSelectedState(@ui.keyboardRightShiftButton)

      , Config.KEYBOARD_SHIFT_THROTTLE_LIMIT_IN_MILLIS

      # Allow the user to shift the keyboard by clicking the corresponding buttons in the UI.

      @ui.keyboardLeftShiftButton.on  'click', => @_shiftKeyboardDownward(instrument)
      @ui.keyboardRightShiftButton.on 'click', => @_shiftKeyboardUpward(instrument)

      # Definte this separate, unthrottled keydown listener simply to prevent default behaviors of any special keys
      # (tab, escape, etc) from firing in between throttled listens above.

      $(document).on 'keydown', (ev) ->
        if ev.keyCode in downwardKeyCodes or ev.keyCode in upwardKeyCodes
          ev.stopPropagation()
          ev.preventDefault()

    _populatePianoKeyLabelsInDom : ->
      @ui.keyboards.each (index, keyboardElem) =>
        $keyboard = $(keyboardElem)

        $whiteKeysInOrder        = @_getDomElementsForWhiteKeysInKeyboard($keyboard)
        $blackKeyWrappersInOrder = @_getDomElementsForBlackKeyWrappersInKeyboard($keyboard)

        $whiteKeysInOrder.each (index, whiteKeyElem) =>

          # Every white key contains a label element, so all white-key key codes should appear in the UI after the
          # following operation.

          pianoKeyId = $(whiteKeyElem).attr('data-piano-key-id')
          $label     = $(whiteKeyElem).find('.KeyanoInstrument-keyLabel')
          $name      = $(whiteKeyElem).find('.KeyanoInstrument-whiteKeyNameLabel')
          $label.text(@KEYBOARD_KEYS_FOR_WHITE_PIANO_KEYS[index].label)
          $name.text(pianoKeyId)

        $blackKeyWrappersInOrder.each (index, blackKeyElem) =>

          # Note that some of these elements wrap "spacers" that will have no label element within them. Setting the
          # .text(...) for these non-existent labels will effectively skip the key code at the current index, which
          # is exactly what we want to happen.

          pianoKeyId = $(blackKeyElem).find('[data-piano-key-id]').attr('data-piano-key-id')
          $label     = $(blackKeyElem).find('.KeyanoInstrument-keyLabel')
          $name      = $(blackKeyElem).find('.KeyanoInstrument-blackKeyNameLabel')
          $label.text(@KEYBOARD_KEYS_FOR_BLACK_PIANO_KEY_WRAPPERS[index].label)
          $name.text(pianoKeyId)


    # Private Methods (Keyboard Shifting)
    # -----------------------------------

    _shiftKeyboardDownward : (instrument) ->
      previousKeyName = pianoKeyUtils.getKeyNameOfNextLowestWhiteKey(@_lowestKeyOfCurrentKeyboardRange)
      @_shiftKeyboardToHaveLowestKey(instrument, previousKeyName)

    _shiftKeyboardUpward : (instrument) ->
      nextKeyName = pianoKeyUtils.getKeyNameOfNextHighestWhiteKey(@_lowestKeyOfCurrentKeyboardRange)
      @_shiftKeyboardToHaveLowestKey(instrument, nextKeyName)

    _shiftKeyboardToHaveLowestKey : (instrument, lowestKeyName) ->
      @_lowestKeyOfCurrentKeyboardRange = lowestKeyName
      @_showDomElementForKeyanoInstrumentWithLowestKey(lowestKeyName)
      keyMappings = @_generateKeyMappingsForInstrumentWithLowestKey(lowestKeyName)
      instrument.activateKeys(keyMappings)

    _generateKeyMappingsForInstrumentWithLowestKey : (lowestKeyName) ->
      $keyboard   = @_getDomElementForKeyboard(lowestKeyName)
      keyMappings = []

      cachedKeyMappings = @_cachedKeyMappingsForKeyboardWithLowestKey[lowestKeyName]
      if cachedKeyMappings?
        keyMappings = cachedKeyMappings
      else
        pianoKeyIdsInOrder = @_getOrderedPianoKeyIdsFromKeyboardDomElement($keyboard)
        keyMappings = _.chain(pianoKeyIdsInOrder)
          .map((pianoKeyId, keyIndex) =>
            result = undefined
            if pianoKeyId?
              result = {
                keyCode  : @KEYBOARD_KEYS_FOR_ALL_PIANO_KEYS[keyIndex].keyCode
                pianoKey : PianoKeys[pianoKeyId]
              }
            return result
          )
          .compact()
          .value()
        @_cachedKeyMappingsForKeyboardWithLowestKey[lowestKeyName] = keyMappings

      return keyMappings


    # Private Methods (DOM Access)
    # ----------------------------

    _showDomElementForKeyanoInstrumentWithLowestKey : (lowestKeyName) ->
      if not _.isString(lowestKeyName)
        throw new Error 'Passed a lowestKeyName to _showKeyanoInstrumentWithLowestKey that was not a string'
      if not pianoKeyUtils.isValidWhiteKeyName(lowestKeyName)
        throw new Error 'Passed an invalid lowestKeyName to _showDefaultKeyanoInstrument'

      @ui.keyboards.hide()
      @_getDomElementForKeyboard(lowestKeyName).show()

    _getDomElementForKeyboard : (lowestKeyName) ->
      return @ui.keyboards.filter("[data-lowest-key='#{lowestKeyName}']")

    _getOrderedPianoKeyIdsFromKeyboardDomElement : ($keyboard) ->
      $whiteKeys        = @_getDomElementsForWhiteKeysInKeyboard($keyboard)
      $blackKeyWrappers = @_getDomElementsForBlackKeyWrappersInKeyboard($keyboard)

      numKeys            = $whiteKeys.size() + $blackKeyWrappers.size()
      pianoKeyIdsInOrder = []
      pianoKeyId         = null

      for keyIndex in _.range(numKeys)
        isEvenIndex = keyIndex % 2 is 0

        if isEvenIndex
          whiteKeyIndex = Math.floor(keyIndex / 2)
          pianoKeyId    = $whiteKeys.eq(whiteKeyIndex).attr('data-piano-key-id')
        else
          blackKeyWrapperIndex = Math.floor(keyIndex / 2)
          $blackKey            = $blackKeyWrappers.eq(blackKeyWrapperIndex).children('.KeyanoInstrument-blackKey')
          pianoKeyId           = $blackKey.attr('data-piano-key-id')

        pianoKeyIdsInOrder.push(pianoKeyId)

      return pianoKeyIdsInOrder

    _getDomElementsForWhiteKeysInKeyboard : ($keyboard) ->
      return $keyboard.find('.KeyanoInstrument-whiteKey')

    _getDomElementsForBlackKeyWrappersInKeyboard : ($keyboard) ->
      return $keyboard.find('.KeyanoInstrument-blackKeyWrapper')


    # Private Methods (Other)
    # -----------------------

    _getSavedVolumeValue : ->
      return parseFloat(window.localStorage[@VOLUME_VALUE_LOCAL_STORAGE_KEY])

    _setSavedVolumeValue : (volumeValue) ->
      window.localStorage[@VOLUME_VALUE_LOCAL_STORAGE_KEY] = volumeValue

    _getSavedVolumeSliderValue : ->
      return parseFloat(window.localStorage[@SLIDER_VALUE_LOCAL_STORAGE_KEY])

    _setSavedVolumeSliderValue : (sliderValue) ->
      window.localStorage[@SLIDER_VALUE_LOCAL_STORAGE_KEY] = sliderValue

    _zipKeyMappingArrays : ({ whiteKeys, blackKeys } = {}) ->
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


  return KeyanoView

