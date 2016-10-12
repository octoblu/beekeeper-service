_             = require 'lodash'
MeshbluConfig = require 'meshblu-config'
Server        = require './src/server'

class Command
  constructor: ->
    @serverOptions = {
      meshbluConfig:  new MeshbluConfig().toJSON()
      port:           process.env.PORT || 80
      disableLogging: process.env.DISABLE_LOGGING == "true"
      mongodbUri:     process.env.MONGODB_URI
      redisNamespace: process.env.REDIS_NAMESPACE || 'beekeeper'
      redisUri:       process.env.REDIS_URI
    }

  panic: (error) =>
    console.error error.stack
    process.exit 1

  run: =>
    @panic new Error('Missing required environment variable: MONGODB_URI') if _.isEmpty @serverOptions.mongodbUri
    @panic new Error('Missing required environment variable: REDIS_URI') if _.isEmpty @serverOptions.redisUri
    # @panic new Error('Missing meshbluConfig') if _.isEmpty @serverOptions.meshbluConfig

    server = new Server @serverOptions
    server.run (error) =>
      return @panic error if error?

      {address,port} = server.address()
      console.log "BeekeeperService listening on port: #{port}"

    process.on 'SIGTERM', =>
      console.log 'SIGTERM caught, exiting'
      return process.exit 0 unless server?.stop?
      server.stop =>
        process.exit 0

command = new Command()
command.run()
