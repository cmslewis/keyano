define [
  'static/js/config/Config'
], (
  Config
) ->

  #
  # Logger
  # ======
  # A utility class for logging statements when Config.DEBUG_MODE is enabled.
  #
  class Logger

    ###
    @params
      contents : (splat of anything you can print via console.log)
    @return
      N/A
    ###
    @debug : (contents...) ->
      if Config.DEBUG_MODE
        console.log(contents)
      return


  return Logger
