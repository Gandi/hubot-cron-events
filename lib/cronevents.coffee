# Description:
#   requests Phabricator Conduit api
#
# Dependencies:
#
# Configuration:
#  PHABRICATOR_URL
#  PHABRICATOR_API_KEY
#  PHABRICATOR_BOT_PHID
#  PHABRICATOR_TRUSTED_USERS
#
# Author:
#   mose

CronJob = require('cron').CronJob

class CronEvents

  constructor: (@robot) ->
    storageLoaded = =>
      @data = @robot.brain.data.cron ||= { }
      @robot.logger.debug 'CronEvents Data Loaded: ' + JSON.stringify(@data, null, 2)
    @robot.brain.on 'loaded', storageLoaded
    storageLoaded() # just in case storage was loaded before we got here
    @jobs = { }

  loadAll: ->
    for name, job of @data
      @jobs[name] = @loadJob job
      if job.started?
        @jobs[name].start()

  loadJob: (job) ->
    params = {
      cronTime: job.cronTime
      start: false
      onTick: ->
        @robot.emit job.eventName, job.eventData
    }
    if job.tz?
      params.tz = job.tz
    return new CronJob(params)

  addJob: (name, period, eventName, tz, cb) ->
    if @_valid period, tz
      @data[name] = {
        cronTime: period,
        eventName: eventName,
        eventData: { },
        started: false,
        tz: tz
      }
      cb { message: "The job #{name} is created. It will stay paused until you start it." }
    else
      cb { message: "Sorry, '#{period}' is not a valid pattern." }

  startJob: (name, cb) ->
    if @data[name]?
      @_start name
      cb { message: "The job #{name} is now in service." }
    else
      cb { message: "startJob: There is no such job named #{name}" }

  stopJob: (name, cb) ->
    if @data[name]?
      @_stop name
      cb { message: "The job #{name} is now paused." }
    else
      cb { message: "stopJob: There is no such job named #{name}" }

  deleteJob: (name, cb) ->
    if @data[name]?
      delete @data[name]
      if @job[name]?
        @jobs[name].stop()
        delete @jobs[name]
      cb { message: "The job #{name} is deleted." }
    else
      cb { message: "deleteJob: There is no such job named #{name}" }

  addData: (name, key, value, cb) ->
    if @data[name]?
      @data[name].eventData[key] = value
      if @job[name]?
        @_stop name
        @_start name
      cb { message: "The key #{key} is now defined for job #{name}." }
    else
      cb { message: "addData: There is no such job named #{name}" }

  dropData: (name, key, cb) ->
    if @data[name]?
      if @data[name].eventData[key]?
        delete @data[name].eventData[key]
      if @job[name]?
        @_stop name
        @_start name
      cb { message: "The key #{key} is now removed from job #{name}." }
    else
      cb { message: "dropData: There is no such job named #{name}" }

  _start: (name) ->
    @jobs[name] = @loadJob @data[name]
    @jobs[name].start()
    @data[name].started = true

  _stop: (name) ->
    if @job[name]?
      @jobs[name].stop()
      delete @jobs[name]
    @data[name].started = false

  _valid: (period, tz) ->
    try
      new CronJob period, ( -> { }), null, false, tz
      return true
    catch e
      @robot.logger.error e
      return false



module.exports = CronEvents
