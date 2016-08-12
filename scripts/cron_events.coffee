# Description:
#   generic event emitter scheduled using cron job
#
# Commands:
#   hubot cron version
#   hubot cron <name> <period> <event> [<tz>]
#   hubot cron start <name>
#   hubot cron stop <name>
#   hubot cron delete <name>
#   hubot cron list [<term>]
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
  robot.respond new RegExp(
    'cron ([^ ]+) ' +
    '([-/0-9\*,]+ [-/0-9\*,]+ [-/0-9\*,]+ [-/0-9\*,]+ [-/0-9\*,]+(?: [-/0-9\*,]+)?)' +
    '(?: ([^ ]+))?(?: ([^ ]+))?$')
  , (res) ->
    name = res.match[1]
    period = res.match[2]
    eventName = res.match[3]
    tz = res.match[4]
    cron.addJob name, period, eventName, tz, (so) ->
      res.send so.message
    res.finish()

  #   hubot cron start <name>
  robot.respond /cron start ([^ ]+)$/, (res) ->
    name = res.match[1]
    cron.startJob name, (so) ->
      res.send so.message
    res.finish()

  #   hubot cron stop <name>
  robot.respond /cron stop ([^ ]+)$/, (res) ->
    name = res.match[1]
    cron.stopJob name, (so) ->
      res.send so.message
    res.finish()

  #   hubot cron delete <name>
  robot.respond /cron delete ([^ ]+)$/, (res) ->
    name = res.match[1]
    cron.deleteJob name, (so) ->
      res.send so.message
    res.finish()

  #   hubot cron list [<term>]
  robot.respond /cron list(?: ([^ ]+))?$/, (res) ->
    filter = res.match[1]
    cron.listJob filter, (so) ->
      for k, v of so
        res.send "#{k} - event #{v.eventName}"
    res.finish()

  #   hubot cron <name> <key> <value>
  robot.respond /cron ([^ ]+) ([^ ]+) = (.+)$/, (res) ->
    name = res.match[1]
    key = res.match[2]
    value = res.match[3]
    cron.addData name, key, value, (so) ->
      res.send so.message
    res.finish()

  #   hubot cron <name> drop <key>
  robot.respond /cron ([^ ]+) drop ([^ ]+)$/, (res) ->
    name = res.match[1]
    key = res.match[2]
    cron.dropData name, key, (so) ->
      res.send so.message
    res.finish()

  # debug
  robot.respond /cron jobs$/, (res) ->
    console.log cron.jobs

  # sample for testing purposes
  robot.on 'cron.message', (e) ->
    if e.room and e.message
      robot.messageRoom e.room, e.message

  # another sample for testing purposes
  robot.on 'cron.date', (e) ->
    if e.room
      robot.messageRoom e.room, new Date()
