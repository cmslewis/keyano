define [
  'static/js/PianoKeys'
], (
  PianoKeys
) ->


  #
  # PIANO_KEY_OCTAVE_INDICES
  # ========================
  # This key=>index mapping gives us O(1) lookup of a key's index within a single octave, dramatically speed up the
  # sort operation.
  #

  PIANO_KEY_OCTAVE_INDICES = {
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
      index = PIANO_KEY_OCTAVE_INDICES[pianoKeyName]

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
        console.error "Tried to get the #{pianoKey.name} an octave below #{pianoKey.id}, but #{lowerKeyId} is not defined in the PianoKeys object"
        return null

      return lowerKey

    getSameKeyInNextHighestOctave : (pianoKey) ->
      thisOctave   = pianoKey.octave
      higherOctave = thisOctave + 1

      higherKeyId = "#{pianoKey.name}#{higherOctave}"
      higherKey   = PianoKeys[higherKeyId]

      if not higherKey?
        console.error "Tried to get the #{pianoKey.name} an octave above #{pianoKey.id}, but #{higherKeyId} is not defined in the PianoKeys object"
        return null

      return higherKey

  }

  return pianoKeyUtils
