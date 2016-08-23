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
  robot.cron = cron

  withPermission = (res, cb) ->
    user = robot.brain.userForName res.envelope.user.name
    if robot.auth? and not robot.auth?.isAdmin(user)
      res.reply "You don't have permission to do that."
      res.finish()
    else
      cb()

  #   hubot cron version
  robot.respond /cron version$/, (res) ->
    pkg = require path.join __dirname, '..', 'package.json'
    res.send "hubot-cron-events module is version #{pkg.version}"
    res.finish()

  #   hubot cron <name> <period> <event> [<tz>]
  robot.respond new RegExp(
    'cron ([^ ]+) ' +
    '([-/0-9\*,]+ [-/0-9\*,]+ [-/0-9\*,]+ [-/0-9\*,]+ [-/0-9\*,]+(?: [-/0-9\*,]+)?)' +
    '(?: ([-_a-zA-Z0-9\.]+))(?: ([^ ]+))?' +
    '(?: with ([-_a-zA-Z0-9]+=.+)+)? *$'
    ), (res) ->
      withPermission res, ->
        name = res.match[1]
        period = res.match[2]
        eventName = res.match[3]
        tz = res.match[4]
        args = { }
        if res.match[5]?
          keys = res.match[5].split(/\=[^=]*(?: |$)/)[0...-1]
          values = res.match[5].split(/(?:(?:^| )[-_a-zA-Z0-9]+)=/)[1..]
          for i, k of keys
            args[k] = values[i]
        cron.addJob name, period, eventName, tz, args, (so) ->
          res.send so.message
        res.finish()

  #   hubot cron start <name>
  robot.respond /cron (?:start|resume) ([^ ]+)$/, (res) ->
    withPermission res, ->
      name = res.match[1]
      cron.startJob name, (so) ->
        res.send so.message
      res.finish()

  #   hubot cron stop <name>
  robot.respond /cron (?:stop|pause) ([^ ]+)$/, (res) ->
    withPermission res, ->
      name = res.match[1]
      cron.stopJob name, (so) ->
        res.send so.message
      res.finish()

  #   hubot cron status <name>
  robot.respond /cron status ([^ ]+)$/, (res) ->
    name = res.match[1]
    cron.statusJob name, (so) ->
      res.send so.message
    res.finish()

  #   hubot cron delete <name>
  robot.respond /cron delete ([^ ]+)$/, (res) ->
    withPermission res, ->
      name = res.match[1]
      cron.deleteJob name, (so) ->
        res.send so.message
      res.finish()

  #   hubot cron list [<term>]
  robot.respond /cron (?:info|show|list)(?: ([^ ]+))?$/, (res) ->
    withPermission res, ->
      filter = res.match[1]
      cron.listJob filter, (so) ->
        if Object.keys(so).length is 0
          if filter?
            res.send "The is no job matching #{filter}"
          else
            res.send 'The is no job defined.'
        else
          for k, v of so
            status = if v.started
              '(active)'
            else
              '(inactive)'
            eventdata = ''
            if Object.keys(v.eventData).length > 0
              eventdata = 'with '
              for datakey, datavalue of v.eventData
                eventdata += "#{datakey}='#{datavalue}' "
            res.send "'#{k}' is #{v.cronTime} #{v.eventName} #{eventdata}#{status}"
      res.finish()

  #   hubot cron <name> <key> <value>
  robot.respond /cron ([^ ]+) ([^ ]+) *= *(.+)$/, (res) ->
    withPermission res, ->
      name = res.match[1]
      key = res.match[2]
      value = res.match[3]
      cron.addData name, key, value, (so) ->
        res.send so.message
      res.finish()

  #   hubot cron <name> drop <key>
  robot.respond /cron ([^ ]+) drop ([^ ]+)$/, (res) ->
    withPermission res, ->
      name = res.match[1]
      key = res.match[2]
      cron.dropData name, key, (so) ->
        res.send so.message
      res.finish()

  # debug
  # robot.respond /cron jobs$/, (res) ->
  #   console.log cron.jobs

  # sample for testing purposes
  robot.on 'cron.message', (e) ->
    if e.room and e.message
      robot.messageRoom e.room, e.message

  # another sample for testing purposes
  robot.on 'cron.date', (e) ->
    if e.room
      robot.messageRoom e.room, new Date()
