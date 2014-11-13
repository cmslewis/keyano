define [
  'static/js/data/ChordData'
  'static/js/data/PianoKeys'
  'static/js/config/Config'
  'static/js/utils/Logger'
], (
  ChordData
  PianoKeys
  Config
  Logger
) ->

  VALID_WHITE_KEY_NAMES = 'ABCDEFG'.split('')


  #
  # PianoKeyOctaveIndices
  # =====================
  # This key=>index mapping gives us O(1) lookup of a key's index within a single octave, dramatically speed up the
  # sort operation. Note that we follow the convention of an octave starting with C and ending with B.
  #

  PianoKeyOctaveIndices = {
    C  : 0
    Db : 1
    D  : 2
    Eb : 3
    E  : 4
    F  : 5
    Gb : 6
    G  : 7
    Ab : 8
    A  : 9
    Bb : 10
    B  : 11
  }


  #
  # IntervalName
  # ============
  # A mapping from interval size (in half steps) to interval name.
  #

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
    13 : 'Minor 9th'
    14 : 'Major 9th'
    15 : 'Minor 10th'
    16 : 'Major 10th'
    17 : 'Perfect 11th'
    18 : 'Diminished 12th'
    19 : 'Perfect 12th'


  #
  # Private Helpers
  # ===============
  # Private helpers for use within public utility methods.
  #

  _pianoKeyIdComparator = (a, b) =>
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

    # By now, we know that the keys are in the same octave.

    aKey = a.substring(0, a.length - 1)
    bKey = b.substring(0, b.length - 1)

    aIndex = pianoKeyUtils.getKeyIndexInOctave(aKey)
    bIndex = pianoKeyUtils.getKeyIndexInOctave(bKey)

    if bIndex < aIndex
      return 1
    if aIndex < bIndex
      return -1

    # By now, we know that the keys are identical.

    return 0

  _identifyInterval = (pianoKeys) ->
    if _.size(pianoKeys) < 2
      throw new Error 'Not enough piano keys provided to _identifyInterval (need exactly 2)'
    if _.size(pianoKeys) > 2
      throw new Error 'Too many piano keys provided to _identifyInterval (need exactly 2)'

    [lowerKey, higherKey] = pianoKeys
    intervalSize = _getIntervalSize(lowerKey, higherKey)

    if not IntervalName[intervalSize]?
      throw new Error "Provided an interval size (#{intervalSize}) that does not appear in the IntervalName object"

    return IntervalName[intervalSize]

  _identifyChord = (pianoKeys) ->
    # If there are only three keys in pianoKeys, then filtering out a higher duplicate will make the resultant pair
    # be identified as an interval (e.g. Major 3rd, Perfect Fifth). It'd be weird to identify a three-note
    # combination as an interval; thus, we only filter out duplicates if there are four or more keys provided.
    if _.size(pianoKeys) >= 4
      filteredKeys = _rejectHigherDuplicatesOfLowerKeys(pianoKeys)
    else
      filteredKeys = pianoKeys

    closedSpellingKeys = _findRecognizedClosedSpelling(filteredKeys)

    signature = _getSignature(closedSpellingKeys)
    chordName = _getChordNameFromSignature(closedSpellingKeys, signature)

    return chordName

  _getSignature = (pianoKeys) ->
    intervalSizes = _getIntervalSizes(pianoKeys)
    signature = intervalSizes.join('-')
    return signature

  _getChordNameFromSignature = (keys, signature) ->
    chordData = ChordData[signature]
    rootKey   = keys[chordData?.root]

    if chordData?
      chordName = "#{rootKey.name} #{chordData.name}"
    else
      chordName = Config.LABEL_FOR_UNRECOGNIZED_CHORDS

    return chordName

  _rejectHigherDuplicatesOfLowerKeys = (pianoKeys) ->
    seenKeyNames = new Set()
    uniqueKeys   = []

    # This loop assumes that pianoKeys is already sorted in ascending order of key index.
    for pianoKey in pianoKeys
      if seenKeyNames.has(pianoKey.name)
        continue
      seenKeyNames.add(pianoKey.name)
      uniqueKeys.push(pianoKey)

    return uniqueKeys

  _findRecognizedClosedSpelling = (pianoKeys) ->
    # We might have already rejected all duplicates, but it's an idempotent operation, so might as well do it again
    # since the correctness of this function absolutely depends on duplicates being rejected.
    filteredKeys     = _rejectHigherDuplicatesOfLowerKeys(pianoKeys)
    filteredKeysCopy = _.cloneDeep(filteredKeys)
    rootKey          = filteredKeys[0]

    chordData = null

    # Keep dropping the highest keys by an octave until we find a defined signature. WARNING: Since we're only dropping
    # notes by an octave, this approach is not a general solution. In particular, it will stop working if the keyboard
    # range is larger than 2 octaves.
    for i in [(filteredKeys.length - 1)..0] by -1
      pianoKey = filteredKeys[i]
      lowerKey = pianoKeyUtils.getSameKeyInNextLowestOctave(pianoKey)

      if not lowerKey?
        break

      if lowerKey.index < rootKey.index
        break

      # Delete the last element (the highest remaining key).
      filteredKeysCopy.splice(filteredKeys.length - 1)

      # Append the same pitch from the lower octave.
      filteredKeysCopy.push(lowerKey)

      # Sort the keys by pitch index.
      filteredKeysCopy.sort((a, b) ->
        if a.index < b.index then return -1
        if a.index > b.index then return 1
        return 0
      )

      signature = _getSignature(filteredKeysCopy)
      chordData = ChordData[signature]
      if chordData?
        break

    if chordData?
      closedSpellingKeys = filteredKeysCopy
    else
      closedSpellingKeys = filteredKeys

    return closedSpellingKeys

  _getIntervalSizes = (pianoKeys) ->
    intervalSizes = [0] # 0 Represents the first key being in unison with itself.

    for i in [1...pianoKeys.length]
      lastPianoKey = pianoKeys[i - 1]
      currPianoKey = pianoKeys[i]
      intervalSize = _getIntervalSize(lastPianoKey, currPianoKey)
      intervalSizes.push(intervalSize)

    return intervalSizes

  _getIntervalSize = (pianoKeyA, pianoKeyB) ->
    return Math.abs(pianoKeyB.index - pianoKeyA.index)


  #
  # pianoKeyUtils
  # =============
  # A collection of stateless utility methods for use in other modules.
  #

  pianoKeyUtils = {

    getSortedPianoKeyIds : (pianoKeyIds) ->
      sortedPianoKeyIds = _.cloneDeep(pianoKeyIds)
      sortedPianoKeyIds.sort(_pianoKeyIdComparator)
      return sortedPianoKeyIds

    getKeyIndexInOctave : (pianoKeyName) ->
      index = PianoKeyOctaveIndices[pianoKeyName]

      if not index?
        console.error "Tried to get the index of an unknown key #{pianoKeyName} within an octave"
        return -1

      return index

    getSameKeyInNextLowestOctave : (pianoKey) ->
      thisOctave  = pianoKey.octave
      lowerOctave = thisOctave - 1

      lowerKeyId = "#{pianoKey.name}#{lowerOctave}"
      lowerKey   = PianoKeys[lowerKeyId]

      if not lowerKey?
        Logger.debug "Tried to get the #{pianoKey.name} an octave below #{pianoKey.id}, but #{lowerKeyId} is not defined in the PianoKeys object"
        return null

      return lowerKey

    getSameKeyInNextHighestOctave : (pianoKey) ->
      thisOctave   = pianoKey.octave
      higherOctave = thisOctave + 1

      higherKeyId = "#{pianoKey.name}#{higherOctave}"
      higherKey   = PianoKeys[higherKeyId]

      if not higherKey?
        Logger.debug "Tried to get the #{pianoKey.name} an octave above #{pianoKey.id}, but #{higherKeyId} is not defined in the PianoKeys object"
        return null

      return higherKey

    getKeyNameOfNextHighestWhiteKey : (whiteKeyName) ->
      if not pianoKeyUtils.isValidWhiteKeyName(whiteKeyName)
        throw new Error "Invalid whiteKeyName #{whiteKeyName}"

      # Wrap around to the beginning if necessary.

      if whiteKeyName is _.last(VALID_WHITE_KEY_NAMES)
        higherKeyIndex = 0
      else
        higherKeyIndex = VALID_WHITE_KEY_NAMES.indexOf(whiteKeyName) + 1

      return VALID_WHITE_KEY_NAMES[higherKeyIndex]

    getKeyNameOfNextLowestWhiteKey : (whiteKeyName) ->
      if not pianoKeyUtils.isValidWhiteKeyName(whiteKeyName)
        throw new Error "Invalid whiteKeyName #{whiteKeyName}"

      # Wrap around to the end if necessary.

      if whiteKeyName is _.first(VALID_WHITE_KEY_NAMES)
        lowerKeyIndex = VALID_WHITE_KEY_NAMES.length - 1
      else
        lowerKeyIndex = VALID_WHITE_KEY_NAMES.indexOf(whiteKeyName) - 1

      return VALID_WHITE_KEY_NAMES[lowerKeyIndex]

    isValidWhiteKeyName : (keyName) ->
      return keyName in VALID_WHITE_KEY_NAMES

    ###
    @params
      (list of objects) [
        {
          id        : (string)  the unique ID for the key
          name      : (string)  the basic name of the key
          octave    : (integer) the index of the octave
          frequency : (float)   the frequency of the pitch
          index     : (integer) the index of the key on the piano keyboard
        }
      ]
    @return
      (string)
        If pianoKeys.length is 0: '' (the empty string)
        If pianoKeys.length is 1: the name of the key. (Ex: C, D, E, etc.)
        If pianoKeys.length is 2: the name of the interval. (Ex: Major 2nd, Major 3rd, etc.)
        If pianoKeys.length >= 3: the name of the chord. (Ex: C Major, G Minor 7 (First Inversion), etc.)
    ###
    identifyPianoKeyCombination : (pianoKeys) ->
      return switch pianoKeys.length
        when 0 then ''
        when 1 then pianoKeys[0].name
        when 2 then _identifyInterval(pianoKeys)
        else _identifyChord(pianoKeys)

  }

  return pianoKeyUtils
