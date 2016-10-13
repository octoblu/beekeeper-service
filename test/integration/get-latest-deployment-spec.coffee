_             = require 'lodash'
shmock        = require 'shmock'
request       = require 'request'
enableDestroy = require 'server-destroy'
Server        = require '../../src/server'
mongojs       = require 'mongojs'

describe 'Get Latest Deployment', ->
  beforeEach (done) ->
    db = mongojs 'test-beekeeper-service', ['deployments']
    @deployments = db.deployments
    db.deployments.remove done

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
        userAuth = new Buffer('some-uuid:some-token').toString 'base64'

        options =
          uri: '/deployments/the-owner/the-service/latest'
          baseUrl: "http://localhost:#{@serverPort}"
          json: true

        request.get options, (error, @response, @body) =>
          done error

      it 'should return a 200', ->
        expect(@response.statusCode).to.equal 200

      it 'should return my record', ->
        expect(@body).to.containSubset some_deployment: 1.87

    context 'when a deployment does not exist', ->
      beforeEach (done) ->
        userAuth = new Buffer('some-uuid:some-token').toString 'base64'

        options =
          uri: '/deployments/the-owner/the-service/latest'
          baseUrl: "http://localhost:#{@serverPort}"
          json: true

        request.get options, (error, @response, @body) =>
          done error

      it 'should return a 404', ->
        expect(@response.statusCode).to.equal 404
