{afterEach, beforeEach, describe, it} = global
{expect}      = require 'chai'
sinon         = require 'sinon'

request       = require 'request'
Server        = require '../../src/server'
Redis         = require 'ioredis'
RedisNS       = require '@octoblu/redis-ns'

describe 'Verify Auth', ->
  beforeEach (done) ->
    client = new Redis 'localhost', dropBufferSupport: true
    @redis = new RedisNS 'test-beekeeper', client
    client.on 'ready', (error) =>
      return done error if error?
      @redis.del 'webhooks', done

  beforeEach (done) ->
    @logFn = sinon.spy()
    serverOptions =
      port: undefined,
      disableLogging: true
      logFn: @logFn
      mongodbUri: 'test-beekeeper-service'
      redisUri: 'localhost'
      redisNamespace: 'test-beekeeper'
      username: 'the-username'
      password: 'the-password'

    @server = new Server serverOptions

    @server.run =>
      @serverPort = @server.address().port
      done()

  afterEach ->
    @server.destroy()

  describe 'when auth fails', ->
    describe 'On POST /webhooks/beekeeper.io', ->
      beforeEach (done) ->
        options =
          uri: '/webhooks/beekeeper.io'
          baseUrl: "http://localhost:#{@serverPort}"
          json: blah: 'blah'
          auth:
            username: 'wrong-username'
            password: 'wrong-password'

        request.post options, (error, @response, @body) =>
          done error

      it 'should return a 401', ->
        expect(@response.statusCode).to.equal 401

    describe 'On POST /webhooks/travis:ci', ->
      beforeEach (done) ->
        options =
          uri: '/webhooks/travis:ci'
          baseUrl: "http://localhost:#{@serverPort}"
          json:
            blah: 'blah'
          auth:
            username: 'the-username'
            password: 'the-password'

        request.post options, (error, @response, @body) =>
          done error

      it 'should return a 401', ->
        expect(@response.statusCode).to.equal 401, @body
