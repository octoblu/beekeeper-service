{afterEach, beforeEach, describe, it} = global
{expect}      = require 'chai'
sinon         = require 'sinon'

request       = require 'request'
Server        = require '../../src/server'
Redis         = require 'ioredis'
RedisNS       = require '@octoblu/redis-ns'
mongojs       = require 'mongojs'

describe 'Add Tag to Deployment', ->
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

  describe 'On POST /deployments/owner_name/repo_name/tag/tags', ->
    describe 'when sending a tagName', ->
      beforeEach (done) ->
        record = { owner_name: 'the-owner', repo_name: 'the-service', tag: 'v1.0.0' }
        @deployments.insert record, done

      beforeEach (done) ->
        options =
          uri: '/deployments/the-owner/the-service/v1.0.0/tags'
          baseUrl: "http://localhost:#{@serverPort}"
          auth:
            username: 'the-username'
            password: 'the-password'
          json:
            tagName: 'ATag'

        request.post options, (error, @response, @body) =>
          done error

      it 'should return a 204', ->
        expect(@response.statusCode).to.equal 204, @body

      it 'should update the deployment into the database', (done) ->
        query = { owner_name: 'the-owner', repo_name: 'the-service', tag: 'v1.0.0' }
        @deployments.findOne query, (error, record) =>
          return done error if error?
          expect(record).to.exist
          expect(record.tags).to.include 'atag'
          done()

    describe 'when missing the tagName', ->
      beforeEach (done) ->
        record = { owner_name: 'the-owner', repo_name: 'the-service', tag: 'v1.0.0' }
        @deployments.insert record, done

      beforeEach (done) ->
        options =
          uri: '/deployments/the-owner/the-service/v1.0.0/tags'
          baseUrl: "http://localhost:#{@serverPort}"
          auth:
            username: 'the-username'
            password: 'the-password'
          json: true

        request.post options, (error, @response, @body) =>
          done error

      it 'should return a 422', ->
        expect(@response.statusCode).to.equal 422, @body

    describe 'when the record does not exists', ->
      beforeEach (done) ->
        options =
          uri: '/deployments/the-owner/the-service/v1.0.0/tags'
          baseUrl: "http://localhost:#{@serverPort}"
          auth:
            username: 'the-username'
            password: 'the-password'
          json:
            tagName: 'this-does-not-matter'

        request.patch options, (error, @response, @body) =>
          done error

      it 'should return a 404', ->
        expect(@response.statusCode).to.equal 404, @body

    describe 'when multiple records are found', ->
      beforeEach (done) ->
        record = { owner_name: 'the-owner', repo_name: 'the-service', tag: 'v1.0.0' }
        @deployments.insert record, done

      beforeEach (done) ->
        record = { owner_name: 'the-owner', repo_name: 'the-service', tag: 'v1.0.0' }
        @deployments.insert record, done

      beforeEach (done) ->
        options =
          uri: '/deployments/the-owner/the-service/v1.0.0/tags'
          baseUrl: "http://localhost:#{@serverPort}"
          auth:
            username: 'the-username'
            password: 'the-password'
          json:
            tagName: 'this-shouldnt-matter'

        request.post options, (error, @response, @body) =>
          done error

      it 'should return a 417', ->
        expect(@response.statusCode).to.equal 417, @body
