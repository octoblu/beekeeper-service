{afterEach, beforeEach, describe, it} = global
{expect}      = require 'chai'
sinon         = require 'sinon'

request       = require 'request'
Server        = require '../../src/server'
Redis         = require 'ioredis'
RedisNS       = require '@octoblu/redis-ns'
mongojs       = require 'mongojs'

describe 'Update Deployment', ->
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

  describe 'On PATCH /deployments/owner_name/repo_name/tag', ->
    describe 'when sending a docker_url', ->
      beforeEach (done) ->
        record = { owner_name: 'the-owner', repo_name: 'the-service', tag: 'v1.0.0' }
        @deployments.insert record, done

      beforeEach (done) ->
        options =
          uri: '/deployments/the-owner/the-SERVice/v1.0.0'
          baseUrl: "http://localhost:#{@serverPort}"
          auth:
            username: 'the-username'
            password: 'the-password'
          json:
            docker_url: 'set_it_to_this'

        request.patch options, (error, @response, @body) =>
          done error

      it 'should return a 204', ->
        expect(@response.statusCode).to.equal 204, @body

      it 'should update the deployment into the database', (done) ->
        query = { owner_name: 'the-owner', repo_name: 'the-service', tag: 'v1.0.0' }
        @deployments.findOne query, (error, record) =>
          return done error if error?
          expect(record).to.exist
          expect(record.docker_url).to.equal 'set_it_to_this'
          done()

    describe 'when missing the docker_url', ->
      beforeEach (done) ->
        record = { owner_name: 'the-owner', repo_name: 'the-service', tag: 'v1.0.0' }
        @deployments.insert record, done

      beforeEach (done) ->
        options =
          uri: '/deployments/the-owner/the-service/v1.0.0'
          baseUrl: "http://localhost:#{@serverPort}"
          auth:
            username: 'the-username'
            password: 'the-password'
          json: true

        request.patch options, (error, @response, @body) =>
          done error

      it 'should return a 422', ->
        expect(@response.statusCode).to.equal 422, @body

      it 'should not update the deployment into the database', (done) ->
        query = { owner_name: 'the-owner', repo_name: 'the-service', tag: 'v1.0.0' }
        @deployments.findOne query, (error, record) =>
          return done error if error?
          expect(record).to.exist
          expect(record.docker_url).to.not.exist
          done()

    describe 'when the record does not exists', ->
      beforeEach (done) ->
        options =
          uri: '/deployments/the-owner/the-service/v1.0.0'
          baseUrl: "http://localhost:#{@serverPort}"
          auth:
            username: 'the-username'
            password: 'the-password'
          json:
            docker_url: 'this-does-not-matter'

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
          uri: '/deployments/the-owner/the-service/v1.0.0'
          baseUrl: "http://localhost:#{@serverPort}"
          auth:
            username: 'the-username'
            password: 'the-password'
          json:
            docker_url: 'this-shouldnt-matter'

        request.patch options, (error, @response, @body) =>
          done error

      it 'should return a 417', ->
        expect(@response.statusCode).to.equal 417, @body

      it 'should not update the deployment into the database', (done) ->
        query = { owner_name: 'the-owner', repo_name: 'the-service', tag: 'v1.0.0' }
        @deployments.find query, (error, records) =>
          return done error if error?
          expect(records[0].docker_url).to.not.exist
          expect(records[1].docker_url).to.not.exist
          done()
