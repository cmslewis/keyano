define [
  'static/js/KeyanoKeyValidator'
], (
  KeyanoKeyValidator
) ->

  #
  # KeyanoInstrument
  # ================
  # Registers piano keys and handles their playback.
  #
  class KeyanoInstrument


    # Private Variables
    # -----------------

    _audioContext                 = null
    _keyMappings                  = null
    _keyValidator                 = null
    _pianoKeyRegistry             = null
    _pitchNodesForActivePianoKeys = null


    # Constructor
    # -----------

    constructor : ->
      @_audioContext                 = new (window.AudioContext || window.webkitAudioContext)
      @_keyMappings                  = []
      @_keyValidator                 = new KeyanoKeyValidator()
      @_pianoKeyRegistry             = {}
      @_pitchNodesForActivePianoKeys = {}


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
      @_keyMappings = _.flatten [@_keyMappings, keyMappings]
      _.forEach keyMappings, @_activateKey
      return


    # Private Methods (Setup)
    # -----------------------

    _activateKey : (keyMapping) =>
      @_keyValidator.validateKeyMapping(keyMapping)

      { keyCode, pianoKey } = keyMapping

      $(document).on 'keydown', (ev) => if ev.keyCode is keyCode then @_startPlayingPianoKeyIfNecessary(pianoKey)
      $(document).on 'keyup',   (ev) => if ev.keyCode is keyCode then @_stopPlayingPianoKeyIfNecessary(pianoKey)

      return

    # Private Methods (Playback)
    # --------------------------

    _startPlayingPianoKeyIfNecessary : (pianoKey) ->
      if @_isPianoKeyPlaying(pianoKey)
        console.log('  ', pianoKey.id, ' is already playing, so not playing it')
        return

      console.log('user pressed the key:', pianoKey.id)

      pitchNode = @_createPitchNodeForPianoKey(pianoKey)

      @_saveActivePianoKeyInstance(pianoKey, pitchNode)

      pitchNode.start()

    _stopPlayingPianoKeyIfNecessary : (pianoKey) ->
      if not @_isPianoKeyPlaying(pianoKey)
        console.log('  ', pianoKey.id, ' is not playing, so not stopping it')
        return

      console.log('user released the key:', pianoKey.id)

      pitchNode = @_getActivePianoKey(pianoKey)
      pitchNode.stop()

      @_deleteActivePianoKeyInstance(pianoKey)

      return

    _createPitchNodeForPianoKey : (pianoKey) ->
      oscillatorNode = @_audioContext.createOscillator()
      oscillatorNode.connect(@_audioContext.destination)
      oscillatorNode.type = 'square'
      oscillatorNode.frequency.value = pianoKey.frequency
      return oscillatorNode

    _isPianoKeyPlaying : (pianoKey) ->
      pitchNode = @_getActivePianoKey(pianoKey)
      return !!pitchNode

    _saveActivePianoKeyInstance : (pianoKey, pitchNode) ->
      @_pitchNodesForActivePianoKeys[pianoKey.id] = pitchNode
      return

    _deleteActivePianoKeyInstance : (pianoKey) ->
      @_pitchNodesForActivePianoKeys[pianoKey.id] = undefined
      return

    _getActivePianoKey : (pianoKey) ->
      return @_pitchNodesForActivePianoKeys[pianoKey.id]

  return KeyanoInstrument
