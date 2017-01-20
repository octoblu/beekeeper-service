enableDestroy     = require 'server-destroy'
octobluExpress    = require 'express-octoblu'
Router            = require './router'
WebhookService    = require './services/webhook-service'
DeploymentService = require './services/deployment-service'
AuthService       = require './services/auth-service'
mongojs           = require 'mongojs'
Redis             = require 'ioredis'
RedisNS           = require '@octoblu/redis-ns'
debug             = require('debug')('beekeeper-service:server')

class Server
  constructor: (options={})->
    {
      @logFn
      @port
      @mongodbUri
      @redisNamespace
      @redisUri
      @username
      @password
      @disableTravisAuth
      @disableLogging
    } = options
    throw new Error 'Server requires: mongodbUri' unless @mongodbUri?
    throw new Error 'Server requires: redisUri' unless @redisUri?
    throw new Error 'Server requires: redisNamespace' unless @redisNamespace?
    throw new Error 'Server requires: username' unless @username?
    throw new Error 'Server requires: password' unless @password?

  address: =>
    @server.address()

  run: (callback) =>
    app = octobluExpress({ @logFn, @disableLogging })

    authService = new AuthService { @username, @password, @disableTravisAuth }
    app.use authService.auth({ travisPath: '/webhooks/travis:ci' })

    db = mongojs @mongodbUri, ['deployments']
    client = new Redis @redisUri, dropBufferSupport: true
    redis = new RedisNS @redisNamespace, client

    deploymentService = new DeploymentService { db, redis }
    webhookService = new WebhookService { redis }
    router = new Router { deploymentService, webhookService }

    router.route app

    @server = app.listen @port, callback
    enableDestroy @server

  stop: (callback) =>
    @server.close callback

  destroy: =>
    @server.destroy()

module.exports = Server
