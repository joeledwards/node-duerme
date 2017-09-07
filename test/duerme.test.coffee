assert = require 'assert'
express = require 'express'
durations = require 'durations'
{poll} = require '../src/index.coffee'

describe "duerme", ->
  port = 42424

  serve = (route, ready) -> 
    new Promise (resolve) ->
      app = express()
      context = {app: app}
      halt = (done) -> context.server.close(-> done() if done?)
      route app
      context.server = app.listen port, -> resolve halt

  it "should confirm a successful connection", ->
    serve (app) ->
      app.get '/stuff', (req, res) -> res.status(200).json({})
    .then (halt) ->
      poll
        quiet: true
        method: 'get'
        url: "http://localhost:#{port}/stuff"
        totalTimeout: 1000
        connectTimeout: 100
        connectFrequency: 10
      .then ({code, attempts}) ->
        assert.equal code, 0, "Should have connected"
        assert.equal attempts, 1, "Should attempted only once"
        halt()

  it "should be able to anticipate error status codes", ->
    serve (app) ->
      app.get '/stuff', (req, res) -> res.status(200).json({})
    .then (halt) ->
      poll
        quiet: true
        method: 'get'
        url: "http://localhost:#{port}/staff"
        status: 404
        totalTimeout: 1000
        connectTimeout: 100
        connectFrequency: 10
      .then ({code, attempts}) ->
        assert.equal code, 0, "Should have connected"
        assert.equal attempts, 1, "Should attempted only once"
        halt()

  it "should retry until API route responds with expected status", ->
    failures = 5
    serve (app) ->
      app.get '/stuff', (req, res) ->
        res.status(if failures-- < 1 then 200 else 404).json({})
    .then (halt) ->
      poll
        quiet: true
        method: 'get'
        url: "http://localhost:#{port}/stuff"
        totalTimeout: 1000
        connectTimeout: 100
        connectFrequency: 10
      .then ({code, attempts}) ->
        assert.equal code, 0, "Should have connected"
        assert.equal attempts, 6, "Should attempted only once"
        halt()

  it "should retry until API route responds with expected body", ->
    failures = 1
    serve (app) ->
      app.get '/stuff', (req, res) ->
        res.status(200).json(if failures-- < 1 then {v: 'mud'} else {v: 'cud'})
    .then (halt) ->
      poll
        quiet: true
        method: 'get'
        url: "http://localhost:#{port}/stuff"
        regex: 'mud'
        totalTimeout: 1000
        connectTimeout: 100
        connectFrequency: 10
      .then ({code, attempts}) ->
        assert.equal code, 0, "Should have connected"
        assert.equal attempts, 2, "Should attempted only once"
        halt()
