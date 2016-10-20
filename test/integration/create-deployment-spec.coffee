{afterEach, beforeEach, describe, it} = global
{expect}      = require 'chai'
sinon         = require 'sinon'

request       = require 'request'
Server        = require '../../src/server'
Redis         = require 'ioredis'
RedisNS       = require '@octoblu/redis-ns'
mongojs       = require 'mongojs'

describe 'Create Deployment', ->
  beforeEach (done) ->
    client = new Redis 'localhost', dropBufferSupport: true
    @redis = new RedisNS 'test-beekeeper', client
    client.on 'ready', (error) =>
      return done error if error?
      @redis.del 'webhooks', done

  beforeEach (done) ->
    db = mongojs 'test-beekeeper-service', ['deployments']
    @deployments = db.deployments
    db.deployments.remove done

  beforeEach (done) ->
    @logFn = sinon.spy()
    serverOptions =
      port: undefined,
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

  describe 'On POST /deployments/owner_name/repo_name/tag', ->
    beforeEach (done) ->
      options =
        uri: '/deployments/the-owner/the-service/v1.0.0'
        baseUrl: "http://localhost:#{@serverPort}"
        auth:
          username: 'the-username'
          password: 'the-password'
        json: true

      request.post options, (error, @response, @body) =>
        done error

    it 'should return a 201', ->
      expect(@response.statusCode).to.equal 201, @body

    it 'should insert the deployment into the database', (done) ->
      @deployments.findOne owner_name: 'the-owner', repo_name: 'the-service', tag: 'v1.0.0', (error, record) =>
        return done error if error?
        expect(record).to.exist
        done()

    it 'should insert the json into the project', (done) ->
      @redis.brpop 'webhooks', 1, (error, result) =>
        return done error if error?
        { body, owner_name, repo_name } = JSON.parse result[1]
        expect(body).to.deep.equal tag: 'v1.0.0', owner_name: 'the-owner', repo_name: 'the-service'
        expect(owner_name).to.equal 'the-owner'
        expect(repo_name).to.equal 'the-service'
        done()
      return # promises
