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
    retry = (requestWatch) ->
      if watch.duration().millis() > totalTimeout
        console.log "All #{attempts} attempts failed over #{watch}"
        resolve 1
      else
        remaining = Math.max 0, connectTimeout - requestWatch.duration().millis()
        cap = Math.max 0, totalTimeout - watch.duration().millis()
        delay = Math.min cap, remaining
        setTimeout doRequest, delay

    # Perform the request
    doRequest = ->
      requestWatch = durations.stopwatch().start()

      request =
        method: method
        url: url
        data: if method == 'get' then undefined else payload
        timeout: connectTimeout
        validateStatus: -> true

      axios request
      .then (response) ->
        attempts++
        if response.status == status
          console.log "Attempt #{attempts} succeeded. Time elapsed: #{watch}" if not quiet
          watch.stop
          resolve 0
        else
          console.log "Attempt #{attempts} failed with status #{response.status} (#{watch} elapsed)" if not quiet
          retry requestWatch
      .catch (error) ->
        attempts++
        console.log "Attempt #{attempts} failed (#{watch} elapsed) : #{error}" if not quiet
        retry requestWatch

    doRequest()

# Parse the method, and return it if valid
parseMethod = (method) ->
  method = method.toUpperCase()
  switch method
    when "OPTIONS", "HEAD", "GET", "POST", "PUT", "PATCH", "DELETE" then method
    else undefined

# If a value is empty-ish, supply an alterate, otherwise the value
orElse = (value, alternate) ->
  if value == NaN
    alternate
  else
    value ? alternate

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
    .option '-v, --verbose', 'make output more verbose (default is false, superceded by -q option)'
    .parse(process.argv)

  config =
    method: program.host ? 'GET'
    payload: program.payload ? {}
    quiet: program.quiet ? false
    status: orElse program.status, 200
    connectTimeout: orElse program.connectTimeout, 1000
    totalTimeout: orElse program.totalTimeout, 15000
    url: program.url ? 'http://localhost:8080'
    verbose: program.verbose ? false

  if config.quiet
    config.verbose = false

  console.log "Config:\n", config if config.verbose

  console.log "Polling #{config.url}" if not config.quiet

  pollRoute config
  .then (code) -> process.exit code

# Module
module.exports =
  poll: pollRoute
  run: runScript

# If run directly
if require.main == module
  runScript()

