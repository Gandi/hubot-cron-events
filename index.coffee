path = require 'path'

module.exports = (robot) ->
  robot.loadFile(path.resolve(__dirname, 'scripts'), 'cron_events.coffee')
