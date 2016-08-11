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

  constructor: (@robot, env) ->
    storageLoaded = =>
      @data = @robot.brain.data.cron ||= { }
      @robot.logger.debug 'CronEvents Data Loaded: ' + JSON.stringify(@data, null, 2)
    @robot.brain.on 'loaded', storageLoaded
    storageLoaded() # just in case storage was loaded before we got here
    @jobs = { }

  loadAll: ->
    for name, job of @data
      @jobs[name] = @loadJob job
      @jobs[name].start()

  loadJob: (job) ->
    params =
      cronTime: job.cronTime
      start: false
      onTick: ->
        @robot.emit job.eventName, job.eventData
    if job.tz?
      params.tz = job.tz
    return new CronJob(params)

  addJob: (name, period, eventName, tz, cb) ->
    if @valid(period)?
      cb { message: "ok" }
    else
      cb { error: "Sorry, '#{period}' is not a valid pattern." }

  valid: (period) ->
    null



module.exports = CronEvents
