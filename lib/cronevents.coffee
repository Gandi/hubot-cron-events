# Description:
#   cron events library
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
    @loadAll()

  loadAll: ->
    for name, job of @data
      if job.started
        @jobs[name] = @loadJob job
        @jobs[name].start()

  loadJob: (job) ->
    params = {
      cronTime: job.cronTime
      start: false
      onTick: =>
        if job.eventName?
          @robot.emit job.eventName, job.eventData
    }
    if job.tz?
      params.tz = job.tz
    return new CronJob(params)

  addJob: (name, period, eventName, tz, options, cb) ->
    if @_valid period, tz
      args = @_extractKeys(options)
      if @data[name]?
        @data[name].cronTime = period
        if eventName?
          @data[name].eventName = eventName
        if tz?
          @data[name].tz = tz
        if args isnt { }
          for k, v of args
            @data[name].eventData[k] = v
        if @jobs[name]?
          @_stop name
          @_start name
        cb { message: "The job #{name} updated." }
      else
        @data[name] = {
          cronTime: period,
          eventName: eventName,
          eventData: args,
          started: false,
          tz: tz
        }
        cb { message: "The job #{name} is created. It will stay paused until you start it." }
    else
      cb { message: "Sorry, '#{period}' is not a valid pattern." }

  startJob: (name, cb) ->
    @withJob name, cb, =>
      if @jobs[name]?
        @_stop name
      @_start name
      cb { message: "The job #{name} is now in service." }

  stopJob: (name, cb) ->
    @withJob name, cb, =>
      @_stop name
      cb { message: "The job #{name} is now paused." }

  statusJob: (name, cb) ->
    @withJob name, cb, =>
      if @jobs[name]?
        cb { message: "The job #{name} is currently running." }
      else
        cb { message: "The job #{name} is paused." }

  deleteJob: (name, cb) ->
    @withJob name, cb, =>
      if @jobs[name]?
        @jobs[name].stop()
        delete @jobs[name]
      delete @data[name]
      cb { message: "The job #{name} is deleted." }

  listJob: (filter, cb) ->
    res = { }
    for k in Object.keys(@data)
      if new RegExp(filter).test k
        res[k] = @data[k]
    cb res

  addData: (name, key, value, cb) ->
    @withJob name, cb, =>
      @data[name].eventData[key] = value
      if @jobs[name]?
        @_stop name
        @_start name
      cb { message: "The key #{key} is now defined for job #{name}." }

  dropData: (name, key, cb) ->
    @withJob name, cb, =>
      if @data[name].eventData[key]?
        delete @data[name].eventData[key]
      if @jobs[name]?
        @_stop name
        @_start name
      cb { message: "The key #{key} is now removed from job #{name}." }

  withJob: (name, cb, docb) ->
    if @data[name]?
      docb()
    else
      cb { message: "There is no such job named #{name}." }

  _start: (name) ->
    @jobs[name] = @loadJob @data[name]
    @jobs[name].start()
    @data[name].started = true

  _stop: (name) ->
    if @jobs[name]?
      @jobs[name].stop()
      delete @jobs[name]
    @data[name].started = false

  _valid: (period, tz) ->
    try
      new CronJob period, null, null, false, tz
      return true
    catch e
      @robot.logger.error e
      return false

  _extractKeys: (str) ->
    args = { }
    if str?
      keys = str.split(/\=[^=]*(?: |$)/)[0...-1]
      values = str.split(/(?:(?:^| )[-_a-zA-Z0-9]+)=/)[1..]
      for i, k of keys
        args[k] = values[i]
    args



module.exports = CronEvents
