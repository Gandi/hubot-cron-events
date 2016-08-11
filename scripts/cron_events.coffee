# Description:
#   generic event emitter scheduled using cron job
#
# Commands:
#   hubot cron version
#   hubot cron <name> <period> [<tz>]
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
  robot.respond /cron version$/, (msg) ->
    pkg = require path.join __dirname, '..', 'package.json'
    msg.send "hubot-cron-events module is version #{pkg.version}"
    msg.finish()


  #   hubot cron <name> <period> [<tz>]
  #   hubot cron start <name>
  #   hubot cron stop <name>
  #   hubot cron delete <name>
  #   hubot cron <name> <key> <value>
  #   hubot cron <name> drop <key>
