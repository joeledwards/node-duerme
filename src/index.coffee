P = require 'bluebird'
axios = require 'axios'
program = require 'commander'
{millis, stopwatch} = require 'durations'
{blue, emoji, gray, green, orange, purple, red, yellow} = require '@buzuli/color'

# Wait for Postgres to become available
pollRoute = (program) ->
  config =
    method: program.method ? 'GET'
    url: program.url ? 'http://localhost:8080'
    payload: program.payload ? '{}'
    status: orElse program.status, 200
    regex: program.regex
    quiet: program.quiet ? false
    connectFrequency: orElse program.connectFrequency, 1000
    connectTimeout: orElse program.connectTimeout, 1000
    totalTimeout: orElse program.totalTimeout, 15000
    verbose: program.verbose ? false

  if config.quiet
    config.verbose = false

  if config.verbose
    console.log "Config:"
    console.log "            method : #{yellow config.method}"
    console.log "               url : #{green config.url}"
    console.log "           payload : #{gray config.payload}"
    console.log "            status : #{orange config.status}"
    console.log "             regex : #{green(config.regex ? '--')}"
    console.log " connect frequency : #{blue millis config.connectFrequency}"
    console.log "   connect timeout : #{blue millis config.connectTimeout}"
    console.log "     total timeout : #{blue millis config.totalTimeout}"
    console.log "             quiet : #{purple config.quiet}"
    console.log "           verbose : #{purple config.verbose}"

  console.log "Polling #{green(config.url)}" if not config.quiet

  new P (resolve, reject) ->
    {
      method, url, payload,
      status, regex, quiet,
      connectFrequency, connectTimeout, totalTimeout
    } = config

    # timeouts in milliseconds
    watch = stopwatch().start()
    connectWatch = stopwatch()
    attempts = 0

    result = (code) ->
      code: code
      duration: watch.duration()
      attempts: attempts

    # Re-try the query after a delay
    retry = (requestWatch) ->
      if watch.duration().millis() > totalTimeout
        watch.stop()
        console.log "#{emoji.key('x')}  All #{orange(attempts)} attempts failed over #{blue(watch)}"
        resolve result(1)
      else
        remaining = Math.max(0, connectFrequency - requestWatch.duration().millis())
        cap = Math.max(0, totalTimeout - watch.duration().millis())
        console.log "remaining=#{remaining} cap=#{cap}"
        delay = Math.min cap, remaining
        setTimeout doRequest, delay

    # Perform the request
    doRequest = ->
      requestWatch = stopwatch().start()

      # Options to axios
      request =
        method: method
        url: url
        data: if method == 'get' then undefined else payload
        timeout: connectTimeout
        validateStatus: -> true # We will do our own validation

      axios request
      .then (response) ->
        checkResponse = (data) ->
          if regex?
            body = if typeof data == 'string' then data else JSON.stringify(data)
            body.match regex
          else
            true

        attempts++
        if response.status == status
          passed = checkResponse response.data
          watch.stop

          if passed
            console.log "#{emoji.key('white_check_mark')}  Attempt #{orange(attempts)} succeeded. Time elapsed: #{blue(watch)}" if not quiet
            resolve result(0)
          else
            console.log "#{emoji.key('warning')}  Attempt #{orange(attempts)} failed due to regex mismatch (#{blue(watch)} elapsed)" if not quiet
            retry requestWatch
        else
          console.log "#{emoji.key('warning')}  Attempt #{orange(attempts)} failed with status #{red(response.status)} (#{blue(watch)} elapsed)" if not quiet
          retry requestWatch
      .catch (error) ->
        attempts++
        console.log "#{emoji.key('warning')}  Attempt #{orange(attempts)} failed (#{blue(watch)} elapsed) : #{red(error)}" if not quiet
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
    .option '-f, --connect-frequency <milliseconds>', 'Retry frequency (default is 1000)', parseInt
    .option '-m, --method <method>', 'HTTP method (default is GET)', parseMethod
    .option '-p, --payload <payload>', 'JSON Payload (default is {})', JSON.parse
    .option '-q, --quiet', 'Silence non-error output (default is false)'
    .option '-r, --regex <regex>', 'Payload validation regex (default is undefined)'
    .option '-s, --status <status>', 'Success status code (default is 200)', parseInt
    .option '-t, --connect-timeout <milliseconds>', 'Individual connection attempt timeout (default is 1000)', parseInt
    .option '-T, --total-timeout <milliseconds>', 'Total timeout across all connect attempts (dfault is 15000)', parseInt
    .option '-u, --url <url>', 'URL (default is http://localhost:8080)'
    .option '-v, --verbose', 'make output more verbose (default is false, superceded by -q option)'
    .parse(process.argv)

  pollRoute program
  .then ({code}) -> process.exit code

# Module
module.exports =
  poll: pollRoute
  run: runScript

# If run directly
if require.main == module
  runScript()
