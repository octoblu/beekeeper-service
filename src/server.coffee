enableDestroy      = require 'server-destroy'
octobluExpress     = require 'express-octoblu'
express            = require 'express'
MeshbluAuth        = require 'express-meshblu-auth'
Router             = require './router'
WebhookService     = require './services/webhook-service'
debug              = require('debug')('beekeeper-service:server')
mongojs            = require 'mongojs'
Redis              = require 'ioredis'
RedisNS            = require '@octoblu/redis-ns'

class Server
  constructor: (options={})->
    {
      @logFn
      @disableLogging
      @port
      @meshbluConfig
      @mongodbUri
      @redisNamespace
      @redisUri
    } = options
    throw new Error 'Server requires: meshbluConfig' unless @meshbluConfig?
    throw new Error 'Server requires: mongodbUri' unless @mongodbUri?
    throw new Error 'Server requires: redisUri' unless @redisUri?
    throw new Error 'Server requires: redisNamespace' unless @redisNamespace?

  address: =>
    @server.address()

  run: (callback) =>
    app = octobluExpress({ @logFn, @disableLogging })

    meshbluAuth = new MeshbluAuth @meshbluConfig
    app.use express.static 'public'

    # app.use meshbluAuth.auth()
    # app.use meshbluAuth.gateway()

    db = mongojs @mongodbUri, ['deployments']
    client = new Redis @redisUri, dropBufferSupport: true
    redis = new RedisNS @redisNamespace, client

    webhookService = new WebhookService { redis }
    router = new Router { webhookService }

    router.route app

    @server = app.listen @port, callback
    enableDestroy @server

  stop: (callback) =>
    @server.close callback

  destroy: =>
    @server.destroy()

module.exports = Server
