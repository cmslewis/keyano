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
  # Registers KeyCode => PianoKey mappings and handles all audio playback. This instrument emits the following events:
  #
  # 'piano:key:did:start:playing' : emitted on $(document) once a piano key's pitch has started playing
  # 'piano:key:did:stop:playing'  : emitted on $(document) once a piano key's pitch has stopped playing
  #

  class KeyanoInstrument


    # Constants
    # ---------

    DURATION_WITHOUT_PEDAL   : 200
    DURATION_WITH_PEDAL      : 3000
    TIMEOUT                  : 50


    # Private Variables
    # -----------------

    _activatedKeyMappings    : null
    _audioContext            : null
    _impressedPianoKeyIds    : null
    _keyValidator            : null
    _masterGainNode          : null
    _nodesForActivePianoKeys : null
    _onKeydownFns            : null
    _onKeyupFns              : null


    # Constructor
    # -----------

    constructor : ->
      @_audioContext         = new (window.AudioContext || window.webkitAudioContext)
      @_impressedPianoKeyIds = {}
      @_keyValidator         = new KeyMappingValidator()
      @_onKeydownFns         = []
      @_onKeyupFns           = []

      @_resetKeyMappings()
      @_resetMasterGainNode()

      @_activatePedalKey(Config.PEDAL_KEY_CODE)

      window.setVolume = _.bind @setVolume, this

    _resetKeyMappings : ->
      @_stopPlayingAllActivePianoKeysImmediately()

      # Clear existing key mappings.

      @_activatedKeyMappings = {}

      # Unbind all key events for the existing key mappings.

      _.forEach @_onKeydownFns, (onKeydownFn) -> $(document).unbind 'keydown', onKeydownFn
      _.forEach @_onKeyupFns,   (onKeyupFn)   -> $(document).unbind 'keyup',   onKeyupFn

      # Clear both arrays of key-event callback functions.

      @_onKeydownFns.length = 0
      @_onKeyupFns.length   = 0

    _resetMasterGainNode : ->
      # Create a single, master gain node that will control the volume for the whole instrument's playback.
      @_masterGainNode = @_createVolumeNode()
      @_masterGainNode.connect(@_audioContext.destination)


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
    ###
    activateKeys : (keyMappings) ->
      @_resetKeyMappings()
      _.forEach keyMappings, @_activateKey
      return

    ###
    @return
      (list) the sorted list of ids for the currently impressed piano keys
    ###
    getImpressedPianoKeys : ->
      pianoKeyIds = _.keys(@_impressedPianoKeyIds)
      sortedPianoKeyIds = pianoKeyUtils.getSortedPianoKeyIds(pianoKeyIds)
      return _.map sortedPianoKeyIds, (pianoKeyId) -> _.cloneDeep PianoKeys[pianoKeyId]

    ###
    @params
      volume : (float) a value between 0 (mute) and 1 (max volume)
    ###
    setVolume : (volume) ->
      if not _.isNumber(volume) and _.isFinite(volume)
        throw new Error 'volume parameter should be of type <float>'

      if volume < 0 then volume = 0
      if volume > 1 then volume = 1

      @_masterGainNode.gain.value = volume
      Logger.debug '@_masterGainNode.gain.value', @_masterGainNode.gain.value


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

      # Keep a reference to each onKeydown function and each onKeyup function, so we can properly unbind them later.

      onKeydownFn = (ev) => if ev.keyCode is keyCode then @_startPlayingPianoKeyIfNecessary(pianoKey)
      onKeyupFn   = (ev) => if ev.keyCode is keyCode then @_stopPlayingPianoKeyIfNecessary(pianoKey)

      @_onKeydownFns.push(onKeydownFn)
      @_onKeyupFns.push(onKeyupFn)

      $(document).on 'keydown', onKeydownFn
      $(document).on 'keyup',   onKeyupFn

      return


    # Private Methods (Teardown)
    # --------------------------

    _stopPlayingAllActivePianoKeysImmediately : ->
      _.forEach @_nodesForActivePianoKeys, (nodesForPianoKey, pianoKeyId) =>
        if not _.isObject(nodesForPianoKey)
          return
        { pitchNode, gainNode } = nodesForPianoKey
        @_stopPitchNodeImmediately(pitchNode, gainNode)
        delete @_impressedPianoKeyIds[pianoKeyId]
        $(document).trigger('piano:key:did:stop:playing', pianoKeyId)
      @_nodesForActivePianoKeys = {}
      $(document).trigger('did:stop:all:piano:keys:immediately')


    # Private Methods (Playback)
    # --------------------------

    _startPlayingPianoKeyIfNecessary : (pianoKey) ->
      if @_isPianoKeyPlaying(pianoKey)
        Logger.debug('  ', pianoKey.id, ' is already playing, so not playing it')
        return

      Logger.debug('user pressed the key:', pianoKey.id)
      @_impressedPianoKeyIds[pianoKey.id] ?= true
      Logger.debug('impressed keys:', @_impressedPianoKeyIds)

      { pitchNode, gainNode } = @_startPitchNode(pianoKey)

      @_saveActivePianoKeyInstance(pianoKey, { pitchNode, gainNode })

      $(document).trigger('piano:key:did:start:playing', pianoKey.id)

    _stopPlayingPianoKeyIfNecessary : (pianoKey, isPedalPressed = true) ->
      if not @_isPianoKeyPlaying(pianoKey)
        Logger.debug('  ', pianoKey.id, ' is not playing, so not stopping it')
        return

      Logger.debug('user released the key:', pianoKey.id)
      delete @_impressedPianoKeyIds[pianoKey.id]

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
      gainNode.connect(@_masterGainNode)
      pitchNode.start(0)

      return { pitchNode, gainNode }

    _stopPitchNodeWithoutPedal : (pitchNode, gainNode) ->
      @_stopPitchNodeOverTime(pitchNode, gainNode, @DURATION_WITHOUT_PEDAL)

    _stopPitchNodeWithPedal : (pitchNode, gainNode) ->
      @_stopPitchNodeOverTime(pitchNode, gainNode, @DURATION_WITH_PEDAL)

    _stopPitchNodeOverTime : (pitchNode, gainNode, duration) ->
      if duration <= 0
        throw new Error 'Duration must be a positive number'

      # This if statement is cruscial to prevent infinite loops after the gain has already reached 0.
      if gainNode.gain.value <= 0
        return

      reductionPerInterval = @TIMEOUT / duration

      pedalInterval = setInterval =>
        if not @_isPedalPressed
          clearInterval(pedalInterval)
          @_stopPitchNodeWithoutPedal(pitchNode, gainNode)
        gainNode.gain.value -= reductionPerInterval
        if gainNode.gain.value <= 0
          clearInterval(pedalInterval)
          @_stopPitchNodeImmediately(pitchNode, gainNode)
      , @TIMEOUT

      $(document).on 'did:stop:all:piano:keys:immediately', =>
        clearInterval(pedalInterval)
        @_stopPitchNodeImmediately(pitchNode, gainNode)

    _stopPitchNodeImmediately : (pitchNode, gainNode) ->
      gainNode.gain.value = 0
      try
        pitchNode.stop(0)
      catch error
        Logger.debug('Attempted to stop a pitchNode that was already stopped', error)

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
