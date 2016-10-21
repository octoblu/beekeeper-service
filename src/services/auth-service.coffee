basicAuthMiddleware = require 'basicauth-middleware'
TravisAuthService   = require './travis-auth-service'
debug               = require('debug')('beekeeper-service:auth-service')

class AuthService
  constructor: ({ username, password, disableTravisAuth }) ->
    throw new Error 'Missing username' unless username?
    throw new Error 'Missing password' unless password?
    @travisAuthService = new TravisAuthService { disableTravisAuth }
    debug 'using auth', { username, password }
    @basicAuth = basicAuthMiddleware username, password

  auth: ({ travisPath }) =>
    throw new Error 'Missing travisPath for travis auth' unless travisPath?
    debug 'travis path', travisPath
    return (request, response, next) =>
      debug 'request.path',    request.path
      debug 'request.headers', request.headers
      debug 'request.params',  request.params
      return @travisAuthService.auth(request, response, next) if request.path == travisPath
      @basicAuth(request, response, next)

module.exports = AuthService
