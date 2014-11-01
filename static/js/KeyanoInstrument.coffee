define [
  'static/js/KeyanoKeyValidator'
  'static/js/Logger'
  'static/js/Config'
  'static/js/PianoKeys'
], (
  KeyanoKeyValidator
  Logger
  Config
  PianoKeys
) ->


  #
  # KeyanoInstrument
  # ================
  # Registers piano keys and handles their playback.
  #
  class KeyanoInstrument


    # Constants
    # ---------

    DURATION_WITHOUT_PEDAL : 100
    DURATION_WITH_PEDAL    : 3000
    TIMEOUT                : 50


    # Private Variables
    # -----------------

    _audioContext            : null
    _impressedKeyIds         : null
    _keyMappings             : null
    _keyValidator            : null
    _pianoKeyRegistry        : null
    _nodesForActivePianoKeys : null


    # Constructor
    # -----------

    constructor : ->
      @_audioContext            = new (window.AudioContext || window.webkitAudioContext)
      @_impressedKeyIds         = {}
      @_keyMappings             = []
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
      @_keyMappings = _.flatten [@_keyMappings, keyMappings]
      _.forEach keyMappings, @_activateKey
      return

    ###
    @return
      (list) the sorted list of ids for the currently impressed piano keys
    ###
    getImpressedPianoKeys : ->
      pianoKeyIds = _.keys(@_impressedKeyIds)
      pianoKeyIds.sort(@_pianoKeyIdComparator)
      return _.map pianoKeyIds, (pianoKeyId) -> _.cloneDeep PianoKeys[pianoKeyId]


    # Private Methods (Setup)
    # -----------------------

    _activatePedalKey : (pedalKeyCode) =>
      $(document).on 'keydown', (ev) => if ev.keyCode is pedalKeyCode then @_isPedalPressed = true
      $(document).on 'keyup',   (ev) => if ev.keyCode is pedalKeyCode then @_isPedalPressed = false

    _activateKey : (keyMapping) =>
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


    # Private Methods (Sorting)
    # -------------------------

    # Unlike a simple array, this gives us O(1) access, dramatically speed up the sort operation.
    PIANO_KEY_INDICES : {
      'C'  : 0
      'Db' : 1
      'D'  : 2
      'Eb' : 3
      'E'  : 4
      'F'  : 5
      'Gb' : 6
      'G'  : 7
      'Ab' : 8
      'A'  : 9
      'Bb' : 10
      'B'  : 11
    }

    _pianoKeyIdComparator : (a, b) =>
      if _.isEmpty(a) and _.isEmpty(b)
        return 0
      if _.isEmpty(b)
        return -1
      if _.isEmpty(a)
        return 1

      # By now, we know that neither key is empty.

      aOctave = parseInt(a[a.length - 1])
      bOctave = parseInt(b[b.length - 1])

      if bOctave < aOctave
        return 1
      if aOctave < bOctave
        return -1

      # By now, we know the keys are in the same octave.

      aKey = a.substring(0, a.length - 1)
      bKey = b.substring(0, b.length - 1)

      aIndex = @PIANO_KEY_INDICES[aKey]
      bIndex = @PIANO_KEY_INDICES[bKey]

      if bIndex < aIndex
        return 1
      if aIndex < bIndex
        return -1

      # By now, we know that the keys are identical.

      return 0


  return KeyanoInstrument
