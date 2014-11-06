define [
  'static/js/KeyanoKeyValidator'
  'static/js/Logger'
  'static/js/Config'
  'static/js/PianoKeys'
  'static/js/pianoKeyUtils'
], (
  KeyanoKeyValidator
  Logger
  Config
  PianoKeys
  pianoKeyUtils
) ->


  #
  # EventNames
  # ==========
  # An enumeration of event names that this module triggers. The purpose here is to keep the event names emitted from
  # KeyanoInstrument in one place for easy reference. Note: You may NOT freely change these event names, as other
  # modules depend on them; again, this enumeration is only here as a convenience for easy reference.
  #
  EventNames =
    ON_KEY_STARTED_PLAYING : 'piano:key:did:start:playing'
    ON_KEY_STOPPED_PLAYING : 'piano:key:did:stop:playing'


  #
  # KeyanoInstrument
  # ================
  # Registers piano keys and handles their playback.
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
    _pianoKeyRegistry        : null
    _nodesForActivePianoKeys : null


    # Constructor
    # -----------

    constructor : ->
      @_audioContext            = new (window.AudioContext || window.webkitAudioContext)
      @_impressedKeyIds         = {}
      @_activatedKeyMappings    = {}
      @_keyValidator            = new KeyanoKeyValidator()
      @_pianoKeyRegistry        = {}
      @_nodesForActivePianoKeys = {}

      @_activatePedalKey(Config.PEDAL_KEY_CODE)


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
      _.forEach keyMappings, @_activateKey
      return

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

      $(document).on 'keydown', (ev) => if ev.keyCode is keyCode then @_startPlayingPianoKeyIfNecessary(pianoKey)
      $(document).on 'keyup',   (ev) => if ev.keyCode is keyCode then @_stopPlayingPianoKeyIfNecessary(pianoKey)

      return


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

      $(document).trigger(EventNames.ON_KEY_STARTED_PLAYING, pianoKey.id)

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

      $(document).trigger(EventNames.ON_KEY_STOPPED_PLAYING, pianoKey.id)

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
