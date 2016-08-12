require('source-map-support').install {
  handleUncaughtExceptions: false,
  environment: 'node'
}

require('es6-promise').polyfill()

Helper = require('hubot-test-helper')

# helper loads a specific script if it's a file
helper = new Helper('../scripts/cron_events.coffee')

# path   = require 'path'
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
          started: true
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

  # ---------------------------------------------------------------------------------
  context 'user starts a job', ->
    beforeEach ->
      room.robot.brain.data.cron = {
        somejob: {
          cronTime: '0 0 1 1 *',
          eventName: 'event1',
          eventData: { },
          started: false
        }
      }
      room.robot.brain.emit 'loaded'

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
          expect(hubotResponse()).to.eql 'infoJob: There is no such job named nojob'

      context 'and job exists', ->
        hubot 'cron info somejob'
        it 'should provide proper information about that job', ->
          expect(hubotResponse()).to.eql "somejob emits 'event1' every '0 0 1 1 *'"

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
            to.eql "somejob emits 'event1' every '0 0 1 1 *' with key1='value1' key2='value2'"


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
            started: false,
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
            to.eql "somejob emits 'event1' every '0 0 1 1 *' (UTC) with key1='value1' key2='value2'"
