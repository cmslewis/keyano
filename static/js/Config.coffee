define [
  'static/js/KeyCodes'
], (
  KeyCodes
) ->

  Config = {
    DEBUG_MODE     : false              # (true|false)
    PITCH_TYPE     : 'square'           # (sine|square)
    PEDAL_KEY_CODE : KeyCodes.SPACE_BAR
  }

  return Config
