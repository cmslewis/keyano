define [
  'static/js/data/KeyCodes'
], (
  KeyCodes
) ->

  #
  # KeyMappingValidator
  # ==================
  # Exposes validation methods for keyboard key => piano key mappings.
  #

  class KeyMappingValidator


    # Public Methods
    # --------------

    validateKeyMapping : (keyMapping) ->
      if not _.isObject(keyMapping)
        throw new Error "Tried to activate a key using an non-object { keyCode, pianoKey } parameter"

      @_validateKeyCode(keyMapping.keyCode)
      @_validatePianoKey(keyMapping.pianoKey)

      return


    # Private Methods
    # ---------------

    ###
    @params
      keyCode : (integer) the keyboard keyCode that will trigger the piano key
    @throws
      Error if
        - The key code is not an integer
        - The key code value is unrecognized
    @return
      N/A
    ###
    _validateKeyCode : (keyCode) ->
      if not _.isNumber(keyCode)
        throw new Error "Tried to activate a key using a non-integer keyCode"
      if not keyCode in _.values(KeyCodes)
        throw new Error "Tried to activate a key using an unrecognized keyCode value"
      return

    ###
    @params
      pianoKey : {
        id        : (string) the unique ID for the piano key
        frequency : (float)  the pitch of the piano key in hertz
      }
    @throws
      Error if
        - The piano key ID is invalid
        - The piano key frequency is invalid
    @return
      N/A
    ###
    _validatePianoKey : (pianoKey) ->
      hasValidId        = _.isString(pianoKey.id)
      hasValidFrequency = _.isNumber(pianoKey.frequency) and _.isFinite(pianoKey.frequency)

      if not hasValidId
        throw new Error "Tried to register a piano key with an non-string ID: #{pianoKey.id}"
      if not hasValidFrequency
        throw new Error "Tried to register a piano key with a non-numeric frequency: #{pianoKey.frequency}"

      return

  return KeyMappingValidator
