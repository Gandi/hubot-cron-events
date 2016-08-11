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



module.exports = CronEvents
