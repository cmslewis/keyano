define [
  'static/js/PianoKeys'
], (
  PianoKeys
) ->

  pianoKeyUtils = {

    getSameKeyInNextLowestOctave : (pianoKey) ->
      thisOctave  = pianoKey.octave
      lowerOctave = thisOctave - 1

      lowerKeyId = "#{pianoKey.name}#{lowerOctave}"
      lowerKey   = PianoKeys[lowerKeyId]

      if not lowerKey?
        console.error "Tried to the #{pianoKey.name} an octave below #{pianoKey.id}, but #{lowerKeyId} is not defined in the PianoKeys object"
        return null

      return lowerKey

    getSameKeyInNextHighestOctave : (pianoKey) ->
      thisOctave   = pianoKey.octave
      higherOctave = thisOctave + 1

      higherKeyId = "#{pianoKey.name}#{higherOctave}"
      higherKey   = PianoKeys[higherKeyId]

      if not higherKey?
        console.error "Tried to the #{pianoKey.name} an octave above #{pianoKey.id}, but #{higherKeyId} is not defined in the PianoKeys object"
        return null

      return higherKey

  }

  return pianoKeyUtils
