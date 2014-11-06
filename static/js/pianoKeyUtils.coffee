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
  # pianoKeyUtils
  # =============
  # A collection of stateless utility methods for use in other modules.
  #

  pianoKeyUtils = {

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
