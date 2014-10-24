define [
  'static/js/Config'
], (
  Config
) ->

  class Logger

    ###
    @params
      contents : (splat of anything you can print via console.log)
    @return
      N/A
    ###
    @debug : (contents...)->
      if Config.DEBUG_MODE
        console.log(contents)
      return

  return Logger
