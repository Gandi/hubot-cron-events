# Description:
#   generic event emitter scheduled using cron job
#
# Commands:
#   hubot cron version
#   hubot cron <name> <period> <event> [<tz>]
#   hubot cron start <name>
#   hubot cron stop <name>
#   hubot cron delete <name>
#   hubot cron <name> <key> <value>
#   hubot cron <name> drop <key>
#
# Author:
#   mose

CronEvents = require '../lib/cronevents'
path       = require 'path'

module.exports = (robot) ->

  cron = new CronEvents robot

  #   hubot cron version
  robot.respond /cron version$/, (res) ->
    pkg = require path.join __dirname, '..', 'package.json'
    res.send "hubot-cron-events module is version #{pkg.version}"
    res.finish()

  #   hubot cron <name> <period> <event> [<tz>]
  robot.respond /cron ([^ ]+) ([-/0-9\*,]+ [-/0-9\*,]+ [-/0-9\*,]+ [-/0-9\*,]+ [-/0-9\*,]+(?: [-/0-9\*,]+)?) ([^ ]+)(?: ([^ ]+))?$/, (res) ->
      name = res.match[1]
      period = res.match[2]
      eventName = res.match[3]
      tz = res.match[4]
      cron.addJob name, period, eventName, tz, (so) ->
        if so.error?
          res.send so.error
        else
          res.send "The job #{name} is created. It will stay paused until you start it."

  #   hubot cron start <name>
  #   hubot cron stop <name>
  #   hubot cron delete <name>
  #   hubot cron <name> <key> <value>
  #   hubot cron <name> drop <key>
