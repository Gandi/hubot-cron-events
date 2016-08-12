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
      hubot 'cron somejob * * * * * some.event'
      it 'should not complain about the period syntax', ->
        expect(hubotResponse()).
          to.eql 'The job somejob is created. It will stay paused until you start it.'

  # ---------------------------------------------------------------------------------
  context 'user starts a job', ->
    beforeEach ->
      room.robot.brain.data.cron = {
        somejob: { 
          cronTime: '* * * * *',
          eventName: 'event1',
          eventData: { }
        }
      }
      afterEach ->
        room.robot.brain.data.cron = { }

    context 'but job is not known', ->
      hubot 'cron start nojob'
      it 'should complain about the period syntax', ->
        expect(hubotResponse()).to.eql "startJob: There is no such job named nojob"

    context 'and job exists', ->
      hubot 'cron start somejob'
      it 'should not complain about the period syntax', ->
        expect(hubotResponse()).
          to.eql 'The job somejob is created. It will stay paused until you start it.'
