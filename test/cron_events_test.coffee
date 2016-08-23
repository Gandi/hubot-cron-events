require('source-map-support').install {
  handleUncaughtExceptions: false,
  environment: 'node'
}

require('es6-promise').polyfill()

Helper = require('hubot-test-helper')

# helper loads a specific script if it's a file
helper = new Helper('../scripts/cron_events.coffee')

path   = require 'path'
sinon  = require 'sinon'
expect = require('chai').use(require('sinon-chai')).expect

room = null

# ---------------------------------------------------------------------------------
describe 'cron_events module', ->

  hubot = (message, userName = 'momo', tempo = 40) ->
    beforeEach (done) ->
      room.user.say userName, "@hubot #{message}"
      setTimeout (done), tempo

  hubotResponse = (i = 1) ->
    room.messages[i]?[1]

  hubotResponseCount = ->
    room.messages?.length - 1

  beforeEach ->
    room = helper.createRoom { httpd: false }
    room.robot.logger.error = sinon.stub()

  # ---------------------------------------------------------------------------------
  context 'at robot launch', ->
    beforeEach ->
      room.robot.brain.data.cron = {
        somejob: {
          cronTime: '0 0 1 1 *',
          eventName: 'event1',
          eventData: { },
          started: false
        },
        other: {
          cronTime: '0 0 1 1 *',
          eventName: 'event2',
          eventData: { },
          started: true,
          tz: 'UTC'
        }
      }
      room.robot.brain.emit 'loaded'
      room.robot.cron.loadAll()

    afterEach ->
      room.robot.brain.data.cron = { }
      room.robot.cron.jobs = { }

    context 'when brain is loaded', ->
      it 'jobs stored as not started are not started', ->
        expect(room.robot.cron.jobs.somejob).not.to.be.defined
      it 'jobs stored as started are started', ->
        expect(room.robot.cron.jobs.other).to.be.defined
      it 'job in brain should have a tz recorded', ->
        expect(room.robot.brain.data.cron.other.tz).to.eql 'UTC'


  # ---------------------------------------------------------------------------------
  context 'user wants to know hubot-cron-events version', ->

    context 'cron version', ->
      hubot 'cron version'
      it 'should reply version number', ->
        expect(hubotResponse()).
          to.match /hubot-cron-events module is version [0-9]+\.[0-9]+\.[0-9]+/
        expect(hubotResponseCount()).to.eql 1

  # ---------------------------------------------------------------------------------
  context 'user adds a new job', ->

    context 'with an invalid period', ->
      hubot 'cron somejob 80 // 80 80 80 some.event'
      it 'should complain about the period syntax', ->
        expect(hubotResponse()).to.eql "Sorry, '80 // 80 80 80' is not a valid pattern."
      it 'should log an error', ->
        expect(room.robot.logger.error).calledOnce

    context 'with a valid period', ->
      hubot 'cron somejob 0 0 1 1 * some.event'
      it 'should not complain about the period syntax', ->
        expect(hubotResponse()).
          to.eql 'The job somejob is created. It will stay paused until you start it.'
      it 'records the new job in the brain', ->
        expect(room.robot.brain.data.cron.somejob).to.exist
      it 'records crontime properly', ->
        expect(room.robot.brain.data.cron.somejob.cronTime).to.eql '0 0 1 1 *'
      it 'records eventname properly', ->
        expect(room.robot.brain.data.cron.somejob.eventName).to.eql 'some.event'

    context 'with a valid period and a tz', ->
      hubot 'cron somejob 0 0 1 1 * some.event UTC'
      it 'should not complain about the period syntax', ->
        expect(hubotResponse()).
          to.eql 'The job somejob is created. It will stay paused until you start it.'
      it 'records timezone properly', ->
        expect(room.robot.brain.data.cron.somejob.tz).to.eql 'UTC'

    context 'with a valid period and some data', ->
      hubot 'cron somejob 0 0 1 1 * some.event UTC with param1=something'
      it 'should not complain about the period syntax', ->
        expect(hubotResponse()).
          to.eql 'The job somejob is created. It will stay paused until you start it.'
      it 'records first param properly', ->
        expect(room.robot.brain.data.cron.somejob.eventData.param1).to.eql 'something'

    context 'with a valid period and some data', ->
      hubot 'cron somejob 0 0 1 1 * some.event UTC with param1=something param2=another'
      it 'should not complain about the period syntax', ->
        expect(hubotResponse()).
          to.eql 'The job somejob is created. It will stay paused until you start it.'
      it 'records first param properly', ->
        expect(room.robot.brain.data.cron.somejob.eventData.param1).to.eql 'something'
      it 'records second param properly', ->
        expect(room.robot.brain.data.cron.somejob.eventData.param2).to.eql 'another'

    context 'with a valid period and some data with spaces', ->
      hubot 'cron somejob 0 0 1 1 * some.event UTC ' +
            'with param1=something and whatever param2=another'
      it 'should not complain about the period syntax', ->
        expect(hubotResponse()).
          to.eql 'The job somejob is created. It will stay paused until you start it.'
      it 'records first param properly', ->
        expect(room.robot.brain.data.cron.somejob.eventData.param1).to.eql 'something and whatever'
      it 'records second param properly', ->
        expect(room.robot.brain.data.cron.somejob.eventData.param2).to.eql 'another'


    context 'and job already runs', ->
      beforeEach ->
        room.robot.brain.data.cron = {
          somejob: {
            cronTime: '0 0 1 1 *',
            eventName: 'event2',
            eventData: {
              someparam: 'somevalue'
            },
            started: true
          }
        }
        room.robot.brain.emit 'loaded'
        room.robot.cron.loadAll()

      afterEach ->
        room.robot.brain.data.cron = { }
        room.robot.cron.jobs = { }

      context 'with simple cronTime update', ->
        hubot 'cron somejob 0 0 1 * * some.event'
        it 'should change the job', ->
          expect(hubotResponse()).to.eql 'The job somejob updated.'
        it 'should have still have the job in the jobs queue', ->
          expect(room.robot.cron.jobs.somejob).to.be.defined
        it 'change the crontime', ->
          expect(room.robot.brain.data.cron.somejob.cronTime).to.eql '0 0 1 * *'
        it 'change the event name', ->
          expect(room.robot.brain.data.cron.somejob.eventName).to.eql 'some.event'

      context 'with tz update', ->
        hubot 'cron somejob 0 0 1 1 * some.event UTC'
        it 'should change the job', ->
          expect(hubotResponse()).to.eql 'The job somejob updated.'
        it 'records timezone properly', ->
          expect(room.robot.brain.data.cron.somejob.tz).to.eql 'UTC'

      context 'with data addition', ->
        hubot 'cron somejob 0 0 1 1 * some.event with param1=value1'
        it 'should change the job', ->
          expect(hubotResponse()).to.eql 'The job somejob updated.'
        it 'keeps existing param', ->
          expect(room.robot.brain.data.cron.somejob.eventData.someparam).to.eql 'somevalue'
        it 'adds the new param', ->
          expect(room.robot.brain.data.cron.somejob.eventData.param1).to.eql 'value1'

      context 'with data update', ->
        hubot 'cron somejob 0 0 1 1 * some.event with someparam=value1'
        it 'should change the job', ->
          expect(hubotResponse()).to.eql 'The job somejob updated.'
        it 'updates existing param', ->
          expect(room.robot.brain.data.cron.somejob.eventData.someparam).to.eql 'value1'

  # ---------------------------------------------------------------------------------
  context 'user starts a job', ->
    beforeEach ->
      room.robot.brain.data.cron = {
        somejob: {
          cronTime: '0 0 1 1 *',
          eventName: 'event1',
          eventData: { },
          started: false
        },
        another: {
          cronTime: '0 0 1 1 *',
          eventName: 'event2',
          eventData: { },
          started: true
        }
      }
      room.robot.brain.emit 'loaded'
      room.robot.cron.loadAll()

    afterEach ->
      room.robot.brain.data.cron = { }
      room.robot.cron.jobs = { }

    context 'but job is not known', ->
      hubot 'cron start nojob'
      it 'should complain about the inexistence of that job', ->
        expect(hubotResponse()).to.eql 'startJob: There is no such job named nojob'
      it 'should not have added a job in the jobs queue', ->
        expect(room.robot.cron.jobs.somejob).not.to.be.defined

    context 'and job exists', ->
      hubot 'cron start somejob'
      it 'should not complain about the period syntax', ->
        expect(hubotResponse()).to.eql 'The job somejob is now in service.'
      it 'should change brain to record it\'s started', ->
        expect(room.robot.brain.data.cron.somejob.started).to.be.true
      it 'should have added a job in the jobs queue', ->
        expect(room.robot.cron.jobs.somejob).to.be.defined

    context 'and job exists and runs', ->
      hubot 'cron start another'
      it 'should change brain to record it\'s still started', ->
        expect(room.robot.brain.data.cron.another.started).to.be.true
      it 'should have added a job in the jobs queue', ->
        expect(room.robot.cron.jobs.another).to.be.defined

  # ---------------------------------------------------------------------------------
  context 'user stops a job', ->
    beforeEach ->
      room.robot.brain.data.cron = {
        somejob: {
          cronTime: '0 0 1 1 *',
          eventName: 'event1',
          eventData: { },
          started: true
        }
      }
      room.robot.brain.emit 'loaded'
      room.robot.cron.loadAll()

    afterEach ->
      room.robot.brain.data.cron = { }
      room.robot.cron.jobs = { }

    context 'but job is not known', ->
      hubot 'cron stop nojob'
      it 'should complain about the inexistence of that job', ->
        expect(hubotResponse()).to.eql 'stopJob: There is no such job named nojob'
      it 'should not have added a job in the jobs queue', ->
        expect(room.robot.cron.jobs.somejob).not.to.be.defined

    context 'and job exists', ->
      hubot 'cron stop somejob'
      it 'should not complain about the inexistence of that job', ->
        expect(hubotResponse()).to.eql 'The job somejob is now paused.'
      it 'should change brain to record it\'s not started', ->
        expect(room.robot.brain.data.cron.somejob.started).to.be.false
      it 'should not have added a job in the jobs queue', ->
        expect(room.robot.cron.jobs.somejob).to.be.undefined

  # ---------------------------------------------------------------------------------
  context 'user asks about the status of a job', ->
    beforeEach ->
      room.robot.brain.data.cron = {
        somejob: {
          cronTime: '0 0 1 1 *',
          eventName: 'event1',
          eventData: { },
          started: false
        },
        other: {
          cronTime: '0 0 1 1 *',
          eventName: 'event2',
          eventData: { },
          started: true
        }
      }
      room.robot.brain.emit 'loaded'
      room.robot.cron.loadAll()

    afterEach ->
      room.robot.brain.data.cron = { }
      room.robot.cron.jobs = { }

    context 'but job is not known', ->
      hubot 'cron status nojob'
      it 'should complain about the inexistence of that job', ->
        expect(hubotResponse()).to.eql 'statusJob: There is no such job named nojob'
      it 'should not be in the jobs queue', ->
        expect(room.robot.cron.jobs.nojob).to.be.undefined

    context 'and job exists and is running', ->
      hubot 'cron status other'
      it 'should not complain about the inexistence of that job', ->
        expect(hubotResponse()).to.eql 'The job other is currently running.'
      it 'should not have added a job in the jobs queue', ->
        expect(room.robot.cron.jobs.other).to.be.defined

    context 'and job exists and is paused', ->
      hubot 'cron status somejob'
      it 'should not complain about the inexistence of that job', ->
        expect(hubotResponse()).to.eql 'The job somejob is paused.'
      it 'should not have added a job in the jobs queue', ->
        expect(room.robot.cron.jobs.somejob).to.be.undefined

  # ---------------------------------------------------------------------------------
  context 'user asks about the info of a job', ->
    context 'but there is no job defined', ->
      beforeEach ->
        room.robot.brain.data.cron = { }
        room.robot.brain.emit 'loaded'
        room.robot.cron.loadAll()

      afterEach ->
        room.robot.brain.data.cron = { }
        room.robot.cron.jobs = { }

      context 'and user wants the whoe list', ->
        hubot 'cron info'
        it 'should complain that there is no job defined', ->
          expect(hubotResponse()).to.eql 'The is no job defined.'

    context 'and this job has no event data', ->
      beforeEach ->
        room.robot.brain.data.cron = {
          somejob: {
            cronTime: '0 0 1 1 *',
            eventName: 'event1',
            eventData: { },
            started: false,
            tz: undefined
          }
        }
        room.robot.brain.emit 'loaded'
        room.robot.cron.loadAll()

      afterEach ->
        room.robot.brain.data.cron = { }
        room.robot.cron.jobs = { }

      context 'but job is not known', ->
        hubot 'cron info nojob'
        it 'should complain about the inexistence of that job', ->
          expect(hubotResponse()).to.eql 'The is no job matching nojob'

      context 'and job exists', ->
        hubot 'cron info somejob'
        it 'should provide proper information about that job', ->
          expect(hubotResponse()).to.eql 'cron somejob 0 0 1 1 * event1 (inactive)'

    context 'and this job has event data', ->
      beforeEach ->
        room.robot.brain.data.cron = {
          somejob: {
            cronTime: '0 0 1 1 *',
            eventName: 'event1',
            eventData: {
              key1: 'value1',
              key2: 'value2'
            },
            started: false,
            tz: undefined
          }
        }
        room.robot.brain.emit 'loaded'

      afterEach ->
        room.robot.brain.data.cron = { }
        room.robot.cron.jobs = { }

      context 'and job exists', ->
        hubot 'cron info somejob'
        it 'should provide proper information about that job', ->
          expect(hubotResponse()).
            to.eql 'cron somejob 0 0 1 1 * event1 with key1=value1 key2=value2 (inactive)'


    context 'and this job has event data and timezone', ->
      beforeEach ->
        room.robot.brain.data.cron = {
          somejob: {
            cronTime: '0 0 1 1 *',
            eventName: 'event1',
            eventData: {
              key1: 'value1',
              key2: 'value2'
            },
            started: true,
            tz: 'UTC'
          }
        }
        room.robot.brain.emit 'loaded'

      afterEach ->
        room.robot.brain.data.cron = { }
        room.robot.cron.jobs = { }

      context 'and job exists', ->
        hubot 'cron info somejob'
        it 'should provide proper information about that job', ->
          expect(hubotResponse()).
            to.eql 'cron somejob 0 0 1 1 * event1 UTC with key1=value1 key2=value2 (active)'

  # ---------------------------------------------------------------------------------
  context 'user deletes a job', ->
    beforeEach ->
      room.robot.brain.data.cron = {
        somejob: {
          cronTime: '0 0 1 1 *',
          eventName: 'event1',
          eventData: { },
          started: true,
          tz: undefined
        }
      }
      room.robot.brain.emit 'loaded'
      room.robot.cron.loadAll()

    afterEach ->
      room.robot.brain.data.cron = { }
      room.robot.cron.jobs = { }

    context 'but job is not known', ->
      hubot 'cron delete nojob'
      it 'should complain about the inexistence of that job', ->
        expect(hubotResponse()).to.eql 'deleteJob: There is no such job named nojob'

    context 'and job exists', ->
      hubot 'cron delete somejob'
      it 'should say that the job is deleted', ->
        expect(hubotResponse()).to.eql 'The job somejob is deleted.'
      it 'should clean the brain of that job', ->
        expect(room.robot.brain.data.cron.somejob).to.be.undefined
      it 'should clean the jobs queue of that job', ->
        expect(room.robot.cron.jobs.somejob).to.be.undefined

  # ---------------------------------------------------------------------------------
  context 'user lists job', ->
    beforeEach ->
      room.robot.brain.data.cron = {
        somejob: {
          cronTime: '0 0 1 1 *',
          eventName: 'event1',
          eventData: { },
          started: false,
          tz: undefined
        },
        someotherjob: {
          cronTime: '0 0 1 1 *',
          eventName: 'event1',
          eventData: { },
          started: false,
          tz: undefined
        },
        anotherjob: {
          cronTime: '0 0 1 1 *',
          eventName: 'event1',
          eventData: { },
          started: true,
          tz: undefined
        }
      }
      room.robot.brain.emit 'loaded'
      room.robot.cron.loadAll()

    afterEach ->
      room.robot.brain.data.cron = { }
      room.robot.cron.jobs = { }

    context 'but there is no match', ->
      hubot 'cron list nojob'
      it 'should warn that there are no matches', ->
        expect(hubotResponse()).to.eql 'The is no job matching nojob'

    context 'and there is one match', ->
      hubot 'cron list somejob'
      it 'should show the matching job', ->
        expect(hubotResponse()).to.eql 'cron somejob 0 0 1 1 * event1 (inactive)'
        expect(hubotResponse(2)).to.be.undefined

    context 'and there is two matches', ->
      hubot 'cron list ome'
      it 'should show the matching jobs', ->
        expect(hubotResponse()).to.eql 'cron somejob 0 0 1 1 * event1 (inactive)'
        expect(hubotResponse(2)).to.eql 'cron someotherjob 0 0 1 1 * event1 (inactive)'
        expect(hubotResponse(3)).to.be.undefined

    context 'and it gets all jobs', ->
      hubot 'cron list'
      it 'should show the whole list of jobs', ->
        expect(hubotResponse()).to.eql 'cron somejob 0 0 1 1 * event1 (inactive)'
        expect(hubotResponse(2)).to.eql 'cron someotherjob 0 0 1 1 * event1 (inactive)'
        expect(hubotResponse(3)).to.eql 'cron anotherjob 0 0 1 1 * event1 (active)'
        expect(hubotResponse(4)).to.be.undefined

  # ---------------------------------------------------------------------------------
  context 'user sets a data param', ->
    beforeEach ->
      room.robot.brain.data.cron = {
        somejob: {
          cronTime: '0 0 1 1 *',
          eventName: 'event1',
          eventData: { },
          started: true,
          tz: undefined
        }
      }
      room.robot.brain.emit 'loaded'
      room.robot.cron.loadAll()

    afterEach ->
      room.robot.brain.data.cron = { }
      room.robot.cron.jobs = { }

    context 'but job is not known', ->
      hubot 'cron nojob key = param'
      it 'should complain about the inexistence of that job', ->
        expect(hubotResponse()).to.eql 'addData: There is no such job named nojob'

    context 'and job exists', ->
      hubot 'cron somejob key = param'
      it 'should say that param is added to data', ->
        expect(hubotResponse()).to.eql 'The key key is now defined for job somejob.'
      it 'should set the key in the brain for taht job', ->
        expect(room.robot.brain.data.cron.somejob.eventData).
          to.eql { key: 'param' }
      it 'should keep the job running', ->
        expect(room.robot.brain.data.cron.somejob.started).to.be.true
      it 'should keep the job in the queue', ->
        expect(room.robot.cron.jobs.somejob).to.be.defined

  # ---------------------------------------------------------------------------------
  context 'user drops a data param', ->
    beforeEach ->
      room.robot.brain.data.cron = {
        somejob: {
          cronTime: '0 0 1 1 *',
          eventName: 'event1',
          eventData: {
            key: 'param',
            key2: 'param2'
          },
          started: true,
          tz: undefined
        }
      }
      room.robot.brain.emit 'loaded'
      room.robot.cron.loadAll()

    afterEach ->
      room.robot.brain.data.cron = { }
      room.robot.cron.jobs = { }

    context 'but job is not known', ->
      hubot 'cron nojob drop key'
      it 'should complain about the inexistence of that job', ->
        expect(hubotResponse()).to.eql 'dropData: There is no such job named nojob'

    context 'and job exists', ->
      hubot 'cron somejob drop key'
      it 'should say that param is added to data', ->
        expect(hubotResponse()).to.eql 'The key key is now removed from job somejob.'
      it 'should set the key in the brain for taht job', ->
        expect(room.robot.brain.data.cron.somejob.eventData).
          to.eql { key2: 'param2' }
      it 'should keep the job running', ->
        expect(room.robot.brain.data.cron.somejob.started).to.be.true
      it 'should keep the job in the queue', ->
        expect(room.robot.cron.jobs.somejob).to.be.defined

  # ---------------------------------------------------------------------------------
  context 'events listeners', ->
    it 'should know about cron.message', ->
      expect(room.robot.events['cron.message']).to.be.defined
    it 'should know about cron.date', ->
      expect(room.robot.events['cron.date']).to.be.defined

    context 'for cron.message', ->
      beforeEach (done) ->
        room.robot.emit 'cron.message', { room: 'room1', message: 'ha' }
        setTimeout (done), 50

      it 'should say that param is added to data', ->
        expect(hubotResponse(0)).to.eql 'ha'

    context 'for cron.date', ->
      beforeEach (done) ->
        room.robot.emit 'cron.date', { room: 'room1' }
        setTimeout (done), 50

      it 'should say that param is added to data', ->
        expect(hubotResponse(0)).to.be.defined

  # ---------------------------------------------------------------------------------
  context 'events triggers', ->
    beforeEach ->
      room.robot.brain.data.cron = {
        somejob: {
          cronTime: '0 0 1 1 *',
          eventName: 'cron.message',
          eventData: { room: 'room1', message: 'ha' },
          started: true,
          tz: undefined
        }
      }
      room.robot.brain.emit 'loaded'
      room.robot.cron.loadAll()

    afterEach ->
      room.robot.brain.data.cron = { }
      room.robot.cron.jobs = { }

    context 'it fires a job on tick', ->
      beforeEach ->
        room.robot.cron.jobs.somejob.fireOnTick()
      it 'should say something', ->
        expect(hubotResponse(0)).to.eql 'ha'

  # ---------------------------------------------------------------------------------
  context 'permissions system', ->
    beforeEach ->
      process.env.HUBOT_AUTH_ADMIN = 'admin_user'
      room.robot.loadFile path.resolve('node_modules/hubot-auth/src'), 'auth.coffee'
      room.robot.brain.userForId 'admin_user', {
        name: 'admin_user'
      }
      room.robot.brain.userForId 'user', {
        name: 'user'
      }

    context 'user wants to stop a job', ->
      beforeEach ->
        room.robot.brain.data.cron = {
          somejob: {
            cronTime: '0 0 1 1 *',
            eventName: 'event1',
            eventData: { },
            started: true
          }
        }
        room.robot.brain.emit 'loaded'
        room.robot.cron.loadAll()

      afterEach ->
        room.robot.brain.data.cron = { }
        room.robot.cron.jobs = { }

      context 'and user is not admin', ->
        hubot 'cron stop somejob', 'user'
        it 'should deny permission to the user', ->
          expect(hubotResponse()).to.eql "@user You don't have permission to do that."
        it 'should change brain to record it\'s not started', ->
          expect(room.robot.brain.data.cron.somejob.started).to.be.true
        it 'should not have added a job in the jobs queue', ->
          expect(room.robot.cron.jobs.somejob).to.be.defined

      context 'and user is admin', ->
        hubot 'cron stop somejob', 'admin_user'
        it 'should comply and stop the job', ->
          expect(hubotResponse()).to.eql 'The job somejob is now paused.'
        it 'should change brain to record it\'s not started', ->
          expect(room.robot.brain.data.cron.somejob.started).to.be.false
        it 'should not have added a job in the jobs queue', ->
          expect(room.robot.cron.jobs.somejob).to.be.undefined
