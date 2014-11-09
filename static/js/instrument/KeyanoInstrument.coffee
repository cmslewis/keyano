define [
  'static/js/instrument/KeyMappingValidator'
  'static/js/utils/Logger'
  'static/js/config/Config'
  'static/js/data/PianoKeys'
  'static/js/utils/pianoKeyUtils'
], (
  KeyMappingValidator
  Logger
  Config
  PianoKeys
  pianoKeyUtils
) ->


  #
  # KeyanoInstrument
  # ================
  # Registers KeyCode => PianoKey mappings and handles all audio playback.
  #
  class KeyanoInstrument


    # Constants
    # ---------

    DURATION_WITHOUT_PEDAL   : 200
    DURATION_WITH_PEDAL      : 3000
    TIMEOUT                  : 50


    # Private Variables
    # -----------------

    _audioContext            : null
    _impressedKeyIds         : null
    _activatedKeyMappings    : null
    _keyValidator            : null
    _nodesForActivePianoKeys : null


    # Constructor
    # -----------

    constructor : ->
      @_audioContext            = new (window.AudioContext || window.webkitAudioContext)
      @_impressedKeyIds         = {}
      @_keyValidator            = new KeyMappingValidator()

      @_reset()
      @_activatePedalKey(Config.PEDAL_KEY_CODE)

    _reset : ->
      @_activatedKeyMappings    = {}
      @_nodesForActivePianoKeys = {}

      $(document).unbind 'keydown', @_onKeyboardKeyDown
      $(document).unbind 'keyup',   @_onKeyboardKeyUp


    # Public Methods
    # --------------

    ###
    @params
      keyMappings : (array of objects) [
        {
          keyCode  : (integer) the keyboard keyCode that will trigger the piano key
          pianoKey : {
            id        : (string) the unique ID for the piano key
            frequency : (float)  the pitch of the piano key in hertz
          }
        },
        ...
      ]
    @events
      'piano:key:did:start:playing' : emitted on $(document) once a piano key's pitch has started playing
      'piano:key:did:stop:playing'  : emitted on $(document) once a piano key's pitch has stopped playing
    ###
    activateKeys : (keyMappings) ->
      @deactivateKeys()
      _.forEach keyMappings, @_activateKey
      return

    deactivateKeys : ->
      @_reset()

    ###
    @return
      (list) the sorted list of ids for the currently impressed piano keys
    ###
    getImpressedPianoKeys : ->
      pianoKeyIds = _.keys(@_impressedKeyIds)
      sortedPianoKeyIds = pianoKeyUtils.getSortedPianoKeyIds(pianoKeyIds)
      return _.map sortedPianoKeyIds, (pianoKeyId) -> _.cloneDeep PianoKeys[pianoKeyId]


    # Private Methods (Setup)
    # -----------------------

    _activatePedalKey : (pedalKeyCode) =>
      $(document).on 'keydown', (ev) => if ev.keyCode is pedalKeyCode then @_isPedalPressed = true
      $(document).on 'keyup',   (ev) => if ev.keyCode is pedalKeyCode then @_isPedalPressed = false

    _activateKey : (keyMapping) =>
      if keyMapping.keyCode is Config.PEDAL_KEY_CODE
        throw new Error "Tried to activate a key #{keyMapping.pianoKey.id} using the key code Config.PEDAL_KEY_CODE, which is already in use by the pedal key."

      if @_activatedKeyMappings[keyMapping.keyCode]?
        throw new Error "Tried to activate a key #{keyMapping.pianoKey.id} using the key code #{keyMapping.keyCode}, which is already mapped to #{@_activatedKeyMappings[keyMapping.keyCode]}"
      @_activatedKeyMappings[keyMapping.keyCode] = keyMapping.pianoKey.id

      Logger.debug('activating piano key', { keyMapping })
      @_keyValidator.validateKeyMapping(keyMapping)

      { keyCode, pianoKey } = keyMapping

      $(document).on 'keydown', @_onKeyboardKeyDown(keyCode, pianoKey)
      $(document).on 'keyup',   @_onKeyboardKeyUp(keyCode, pianoKey)

      return

    _onKeyboardKeyDown : (keyCode, pianoKey) =>
      return (ev) =>
        if ev.keyCode is keyCode
          @_startPlayingPianoKeyIfNecessary(pianoKey)

    _onKeyboardKeyUp : (keyCode, pianoKey) =>
      return (ev) =>
        if ev.keyCode is keyCode
          @_stopPlayingPianoKeyIfNecessary(pianoKey)


    # Private Methods (Playback)
    # --------------------------

    _startPlayingPianoKeyIfNecessary : (pianoKey) ->
      if @_isPianoKeyPlaying(pianoKey)
        Logger.debug('  ', pianoKey.id, ' is already playing, so not playing it')
        return

      Logger.debug('user pressed the key:', pianoKey.id)
      @_impressedKeyIds[pianoKey.id] ?= true
      Logger.debug('impressed keys:', @_impressedKeyIds)

      { pitchNode, gainNode } = @_startPitchNode(pianoKey)

      @_saveActivePianoKeyInstance(pianoKey, { pitchNode, gainNode })

      $(document).trigger('piano:key:did:start:playing', pianoKey.id)

    _stopPlayingPianoKeyIfNecessary : (pianoKey, isPedalPressed = true) ->
      if not @_isPianoKeyPlaying(pianoKey)
        Logger.debug('  ', pianoKey.id, ' is not playing, so not stopping it')
        return

      Logger.debug('user released the key:', pianoKey.id)
      delete @_impressedKeyIds[pianoKey.id]

      { pitchNode, gainNode } = @_getActivePianoKey(pianoKey)
      if @_isPedalPressed
        @_stopPitchNodeWithPedal(pitchNode, gainNode)
      else
        @_stopPitchNodeWithoutPedal(pitchNode, gainNode)

      $(document).trigger('piano:key:did:stop:playing', pianoKey.id)

      @_deleteActivePianoKeyInstance(pianoKey)

      return

    _createPitchNodeForPianoKey : (pianoKey) ->
      oscillatorNode = @_audioContext.createOscillator()
      oscillatorNode.type = Config.PITCH_TYPE
      oscillatorNode.frequency.value = pianoKey.frequency
      return oscillatorNode

    _createVolumeNode : ->
      return @_audioContext.createGain()

    _startPitchNode : (pianoKey) ->
      pitchNode = @_createPitchNodeForPianoKey(pianoKey)
      gainNode  = @_createVolumeNode()
      pitchNode.connect(gainNode)
      gainNode.connect(@_audioContext.destination)
      pitchNode.start()

      return { pitchNode, gainNode }

    _stopPitchNodeWithoutPedal : (pitchNode, gainNode) ->
      @_stopPitchNodeOverTime(pitchNode, gainNode, @DURATION_WITHOUT_PEDAL)

    _stopPitchNodeWithPedal : (pitchNode, gainNode) ->
      @_stopPitchNodeOverTime(pitchNode, gainNode, @DURATION_WITH_PEDAL)

    _stopPitchNodeOverTime : (pitchNode, gainNode, duration) ->
      reductionPerInterval = @TIMEOUT / duration

      pedalInterval = setInterval =>
        if not @_isPedalPressed
          clearInterval(pedalInterval)
          @_stopPitchNodeWithoutPedal(pitchNode, gainNode)
        gainNode.gain.value -= reductionPerInterval
        if gainNode.gain.value <= 0
          clearInterval(pedalInterval)
          pitchNode.stop()
      , @TIMEOUT

    _isPianoKeyPlaying : (pianoKey) ->
      pitchNode = @_getActivePianoKey(pianoKey)
      return !!pitchNode

    _saveActivePianoKeyInstance : (pianoKey, { pitchNode, gainNode }) ->
      @_nodesForActivePianoKeys[pianoKey.id] = { pitchNode, gainNode }
      return

    _deleteActivePianoKeyInstance : (pianoKey) ->
      @_nodesForActivePianoKeys[pianoKey.id] = undefined
      return

    _getActivePianoKey : (pianoKey) ->
      return @_nodesForActivePianoKeys[pianoKey.id]


  return KeyanoInstrument
