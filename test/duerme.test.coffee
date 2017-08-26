assert = require 'assert'
durations = require 'durations'
waitForPg = require '../src/index.coffee'

describe "duerme", ->
    it "should retry until API route responds as expected", (done) ->
        watch = durations.stopwatch().start()

        # TODO: test wait for connection

