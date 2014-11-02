define [
  'static/js/KeyCodes'
], (
  KeyCodes
) ->

  Config = {
    DEBUG_MODE     : false              # (true|false)
    PITCH_TYPE     : 'sine'           # (sine|square|sawtooth|triangle)
    PEDAL_KEY_CODE : KeyCodes.SPACE_BAR
  }

  return Config
