Q = require 'q'
Redis = require 'ioredis'
program = require 'commander'
durations = require 'durations'

# Wait for Postgres to become available
waitForRedis = (config) ->
  deferred = Q.defer()

  # timeouts in milliseconds
  connectTimeout = config.connectTimeout
  totalTimeout = config.totalTimeout

  quiet = config.quiet

  attempts = 1
  watch = durations.stopwatch().start()
  connectWatch = durations.stopwatch()

  wrapup = (code) ->
    if connected
      redis.disconnect()
    deferred.resolve code

  options =
    port: program.port ? 6379
    host: program.host ? 'localhost'
    password: program.password ? null
    lazyConnect: true
    connectTimeout: connectTimeout
    retryStrategy : (times) ->
      attempts = times + 1 
      console.log "Attempt #{times} timed out. Time elapsed: #{watch}" if not quiet
      if watch.duration().millis() > totalTimeout
        console.log "Could not connect to Redis."
        wrapUp(1)
      Math.min connectTimeout, Math.max(0, totalTimeout - watch.duration().millis())

  redis = new Redis(options)
  connected = false

  redis.info 'server'
  .then (result) ->
    connected = true
    watch.stop()
    console.log "Connected. #{attempts} attempt(s) over #{watch}" if not quiet
    wrapup(0)
  .catch (error) ->
    console.log "Error:", error, "\nStack:\n", error.stack
    wrapup(1)

  deferred.promise

# Script was run directly
runScript = () ->
  program
    .option '-D, --database <db_number>', 'Redis database (default is 0)'
    .option '-h, --host <hostname>', 'Redis host (default is localhost)'
    .option '-p, --port <port>', 'Redis port (default is 6379)', parseInt
    .option '-P, --password <password>', 'Redis auth password (default is empty)'
    .option '-q, --quiet', 'Silence non-error output (default is false)'
    .option '-t, --connect-timeout <milliseconds>', 'Individual connection attempt timeout (default is 250)', parseInt
    .option '-T, --total-timeout <milliseconds>', 'Total timeout across all connect attempts (dfault is 15000)', parseInt
    .parse(process.argv)

  config =
    host: program.host ? 'localhost'
    port: program.port ? 6379
    password: program.password ? null
    database: program.database ? 0
    connectTimeout: program.connectTimeout ? 250
    totalTimeout: program.totalTimeout ? 15000
    quiet: program.quiet ? false


  waitForRedis(config)
  .then (code) ->
    process.exit code

# Module
module.exports =
  await: waitForRedis
  run: runScript

# If run directly
if require.main == module
  runScript()

