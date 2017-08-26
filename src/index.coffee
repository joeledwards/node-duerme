P = require 'bluebird'
axios = require 'axios'
program = require 'commander'
durations = require 'durations'

# Wait for Postgres to become available
pollRoute = (config) ->
  new P (resolve, reject) ->
    {
      method, url, payload,
      status, quiet, connectTimeout, totalTimeout
    } = config

    # timeouts in milliseconds
    watch = durations.stopwatch().start()
    connectWatch = durations.stopwatch()
    attempts = 0

    # Re-try the query after a delay
    retry = ->
      if watch.duration().millis() > totalTimeout
        console.log "All #{attempts} attempts failed over #{watch}"
        resolve 1
      else
        delay = Math.min connectTimeout, Math.max(0, totalTimeout - watch.duration().millis())
        setTimeout doRequest, delay

    # Perform the request
    doRequest = ->
      request =
        method: method
        url: url
        data: if method == 'get' then undefined else payload
        timeout: connectTimeout

      axios request
      .then (response) ->
        attempts = attempts + 1 
        if response.status == status
          console.log "Attempt #{attempts} succeeded. Time elapsed: #{watch}" if not quiet
          watch.stop
          resolve 0
        else
          console.log "Attempt #{attempts} failed with status #{response.status} (#{watch} elapsed)" if not quiet
          retry()
      .catch (error) ->
        console.log "Attempt #{attempts} failed (#{watch} elapsed) : #{error}" if not quiet
        retry()

    doRequest()

# Parse the method, and return it if valid
parseMethod = (method) ->
  method = method.toUpperCase()
  switch method
    when "OPTIONS", "HEAD", "GET", "POST", "PUT", "PATCH", "DELETE" then method
    else throw new Error("Invalid method \"#{method}\"")

# Script was run directly
runScript = () ->
  program
    .option '-m, --method <method>', 'HTTP method (default is GET)', parseMethod
    .option '-p, --payload <payload>', 'JSON Payload (default is {})', JSON.parse
    .option '-q, --quiet', 'Silence non-error output (default is false)'
    .option '-s, --status <status>', 'Success status code (default is 200)', parseInt
    .option '-t, --connect-timeout <milliseconds>', 'Individual connection attempt timeout (default is 250)', parseInt
    .option '-T, --total-timeout <milliseconds>', 'Total timeout across all connect attempts (dfault is 15000)', parseInt
    .option '-u, --url <url>', 'URL (default is http://localhost:8080)'
    .parse(process.argv)

  config =
    method: program.host ? 'GET'
    payload: program.payload ? {}
    quiet: program.quiet ? false
    status: program.status ? 200
    connectTimeout: program.connectTimeout ? 1000
    totalTimeout: program.totalTimeout ? 15000
    url: program.url ? 'http://localhost:8080'

  pollRoute config
  .then (code) -> process.exit code

# Module
module.exports =
  poll: pollRoute
  run: runScript

# If run directly
if require.main == module
  runScript()

