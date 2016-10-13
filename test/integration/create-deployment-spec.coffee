_             = require 'lodash'
shmock        = require 'shmock'
request       = require 'request'
enableDestroy = require 'server-destroy'
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

  describe 'On POST /deployments/owner_name/repo_name/tag', ->
    beforeEach (done) ->
      userAuth = new Buffer('some-uuid:some-token').toString 'base64'

      options =
        uri: '/deployments/the-owner/the-service/v1.0.0'
        baseUrl: "http://localhost:#{@serverPort}"
        json: true

      request.post options, (error, @response, @body) =>
        done error

    it 'should return a 201', ->
      expect(@response.statusCode).to.equal 201

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
