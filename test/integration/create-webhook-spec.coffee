{afterEach, beforeEach, describe, it} = global
{expect}      = require 'chai'
sinon         = require 'sinon'

shmock        = require 'shmock'
request       = require 'request'
enableDestroy = require 'server-destroy'
Server        = require '../../src/server'
Redis         = require 'ioredis'
RedisNS       = require '@octoblu/redis-ns'

describe 'Webhooks', ->
  beforeEach (done) ->
    client = new Redis 'localhost', dropBufferSupport: true
    @redis = new RedisNS 'test-beekeeper', client
    client.on 'ready', (error) =>
      return done error if error?
      @redis.del 'webhooks', done

  beforeEach (done) ->
    @meshblu = shmock 0xd00d
    enableDestroy @meshblu

    @logFn = sinon.spy()
    serverOptions =
      port: undefined,
      disableLogging: true
      logFn: @logFn
      mongodbUri: 'test-beekeeper-service'
      redisUri: 'localhost'
      redisNamespace: 'test-beekeeper'
      meshbluConfig:
        hostname: 'localhost'
        protocol: 'http'
        resolveSrv: false
        port: 0xd00d

    @server = new Server serverOptions

    @server.run =>
      @serverPort = @server.address().port
      done()

  afterEach ->
    @meshblu.destroy()
    @server.destroy()

  describe 'On POST /webhooks/beekeeper.io', ->
    beforeEach (done) ->
      options =
        uri: '/webhooks/beekeeper.io'
        baseUrl: "http://localhost:#{@serverPort}"
        json: blah: 'blah'

      request.post options, (error, @response, @body) =>
        done error

    it 'should return a 201', ->
      expect(@response.statusCode).to.equal 201

    it 'should insert the json into the project', (done) ->
      @redis.brpop 'webhooks', 1, (error, result) =>
        return done error if error?
        { body } = JSON.parse result[1]
        expect(body).to.deep.equal blah: 'blah'
        done()
      return # promises

  describe 'On POST /webhooks/something/foo/blah', ->
    beforeEach (done) ->
      options =
        uri: '/webhooks/something:else/foo/blah'
        baseUrl: "http://localhost:#{@serverPort}"
        json: blah: 'blah'

      request.post options, (error, @response, @body) =>
        done error

    it 'should return a 201', ->
      expect(@response.statusCode).to.equal 201

    it 'should insert the json into the project', (done) ->
      @redis.brpop 'webhooks', 1, (error, result) =>
        return done error if error?
        { body, owner_name, repo_name } = JSON.parse result[1]
        expect(body).to.deep.equal blah: 'blah'
        expect(owner_name).to.equal 'foo'
        expect(repo_name).to.equal 'blah'
        done()
      return # promises

  describe 'On POST with payload', ->
    beforeEach (done) ->
      options =
        uri: '/webhooks/something:else/foo/blah'
        baseUrl: "http://localhost:#{@serverPort}"
        json: payload: JSON.stringify blah: 'blah'

      request.post options, (error, @response, @body) =>
        done error

    it 'should return a 201', ->
      expect(@response.statusCode).to.equal 201

    it 'should insert the json into the project', (done) ->
      @redis.brpop 'webhooks', 1, (error, result) =>
        return done error if error?
        { body, owner_name, repo_name } = JSON.parse result[1]
        expect(body).to.deep.equal blah: 'blah'
        expect(owner_name).to.equal 'foo'
        expect(repo_name).to.equal 'blah'
        done()
      return # promises
