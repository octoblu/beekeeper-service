{afterEach, beforeEach, context, describe, it} = global
{expect}      = require 'chai'
sinon         = require 'sinon'

moment        = require 'moment'
request       = require 'request'
Server        = require '../../src/server'
mongojs       = require 'mongojs'

describe 'Get Latest Deployment', ->
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

  describe 'On GET /deployments/:owner_name/:repo_name/latest', ->
    context 'when a deployment exists', ->
      beforeEach (done) ->
        record =
          owner_name: 'the-owner'
          repo_name: 'the-service'
          docker_url: 'the-owner/the-service:v1.0.0'
          ci_passing: true
          created_at: new Date()
          some_deployment: 1.87

        @deployments.insert record, done

      beforeEach (done) ->
        options =
          uri: '/deployments/the-owner/the-service/latest'
          baseUrl: "http://localhost:#{@serverPort}"
          json: true
          auth:
            username: 'the-username'
            password: 'the-password'

        request.get options, (error, @response, @body) =>
          done error

      it 'should return a 200', ->
        expect(@response.statusCode).to.equal 200, JSON.stringify(@body)

      it 'should return my record', ->
        expect(@body).to.containSubset some_deployment: 1.87

    context 'when a deployment does not exist', ->
      beforeEach (done) ->
        options =
          uri: '/deployments/the-owner/the-service/latest'
          baseUrl: "http://localhost:#{@serverPort}"
          json: true
          auth:
            username: 'the-username'
            password: 'the-password'


        request.get options, (error, @response, @body) =>
          done error

      it 'should return a 404', ->
        expect(@response.statusCode).to.equal 404

    context 'when two deployments exist', ->
      beforeEach (done) ->
        record =
          owner_name: 'the-owner'
          repo_name: 'the-service'
          tag: 'v1.0.0'
          docker_url: 'the-owner/the-service:v1.0.0'
          ci_passing: true
          created_at: moment.utc().subtract(1, 'hour').toDate()
          some_deployment: 1.87

        @deployments.insert record, done

      beforeEach (done) ->
        record =
          owner_name: 'the-owner'
          repo_name: 'the-service'
          tag: 'v2.0.0'
          docker_url: 'the-owner/the-service:v2.0.0'
          ci_passing: true
          created_at: moment.utc().toDate()
          some_deployment: 1.87

        @deployments.insert record, done

      beforeEach (done) ->
        options =
          uri: '/deployments/the-owner/the-service/latest'
          baseUrl: "http://localhost:#{@serverPort}"
          json: true
          auth:
            username: 'the-username'
            password: 'the-password'

        request.get options, (error, @response, @body) =>
          done error

      it 'should return a 200', ->
        expect(@response.statusCode).to.equal 200, JSON.stringify(@body)

      it 'should return the v2.0.0 record', ->
        expect(@body).to.containSubset tag: 'v2.0.0'
