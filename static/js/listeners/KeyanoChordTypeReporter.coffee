define [
  'static/js/listeners/AbstractKeyanoListener'
  'static/js/data/ChordData'
], (
  AbstractKeyanoListener
  ChordData
) ->

  IntervalName =
    1  : 'Minor 2nd'
    2  : 'Major 2nd'
    3  : 'Minor 3rd'
    4  : 'Major 3rd'
    5  : 'Perfect 4th'
    6  : 'Tritone'
    7  : 'Perfect 5th'
    8  : 'Minor 6th'
    9  : 'Major 6th'
    10 : 'Minor 7th'
    11 : 'Major 7th'
    12 : 'Octave'


  class KeyanoChordTypeReporter extends AbstractKeyanoListener


    # Instance Variables
    # ------------------

    keyanoKeys : null


    # Overridden Methods
    # ------------------

    activate : (keyanoKeys, $outputElem) ->
      @keyanoKeys  = keyanoKeys
      @$outputElem = $outputElem
      super

    onPianoKeyStartedPlaying : (ev, pianoKeyId) ->
      @_printChord()
      return

    onPianoKeyStoppedPlaying : (ev, pianoKeyId) ->
      @_printChord()
      return


    # Private Methods
    # ---------------

    _printChord : ->
      impressedPianoKeys = @instrument.getImpressedPianoKeys()

      if impressedPianoKeys.length <= 1
        @$outputElem?.text('')
        return
      else if impressedPianoKeys.length is 2
        name = @_identifyInterval(impressedPianoKeys)
      else
        name = @_identifyChord(impressedPianoKeys)

      @$outputElem?.text(name)

      return

    _identifyInterval : (pianoKeys) ->
      if _.size(pianoKeys) < 2
        throw new Error 'Not enough piano keys provided to _identifyInterval (need exactly 2)'
      if _.size(pianoKeys) > 2
        throw new Error 'Too many piano keys provided to _identifyInterval (need exactly 2)'

      [lowerKey, higherKey] = pianoKeys
      intervalSize = @_getIntervalSize(lowerKey, higherKey)

      return IntervalName[intervalSize]

    ###
    Returns the name of the chord indicated by the provided piano key combination.
    @params
      pianoKeys : [
        <pianoKeyId> (string),
        ...
      ]
    @return
      (string) the name of the chord (e.g. CM7)
    ###
    _identifyChord : (pianoKeys) ->
      signature = @_getIntervalSizesSignature(pianoKeys)
      chordData = ChordData[signature]

      chordName = null
      if chordData?
        rootKeyName = pianoKeys[chordData.root].name
        chordName   = "#{rootKeyName} #{chordData.quality}"
      else
        chordName = signature
      return chordName

    ###
    @params
      pianoKeyA, pianoKeyB : {
        id        : (string)
        frequency : (float)
        index     : (integer)
      }
    @return
      (integer) the size of the interval
    ###
    _getIntervalSize : (pianoKeyA, pianoKeyB) ->
      return Math.abs(pianoKeyB.index - pianoKeyA.index)

    _getIntervalSizes : (pianoKeys) ->
      intervalSizes = [0] # 0 Represents the first key being in unison with itself.

      for i in [1...pianoKeys.length]
        lastPianoKey = pianoKeys[i - 1]
        currPianoKey = pianoKeys[i]
        intervalSize = @_getIntervalSize(lastPianoKey, currPianoKey)
        intervalSizes.push(intervalSize)

      return intervalSizes

    _getIntervalSizesSignature : (pianoKeys) ->
      intervalSizes = @_getIntervalSizes(pianoKeys)
      signature = intervalSizes.join('-')
      return signature


  return KeyanoChordTypeReporter
