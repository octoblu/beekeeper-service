request = require 'request'
crypto  = require 'crypto'
debug   = require('debug')('beekeeper-service:travis-auth-service')

TRAVIS_PRO_URI = 'https://api.travis-ci.com/config'
TRAVIS_ORG_URI = 'https://api.travis-ci.org/config'

class TravisAuthService
  constructor: ({ @disableTravisAuth }) ->

  auth: (request, response, next) =>
    debug 'auth both'
    return next() if @disableTravisAuth
    @_authOrg request, response, (error) =>
      return next(error) if error?
      @_authPro request, response, next

  _authPro: (request, response, next) =>
    debug 'auth pro'
    @_getProPublicKey @_handleResponse request, response, next

  _authOrg: (request, response, next) =>
    debug 'auth org'
    @_getOrgPublicKey @_handleResponse request, response, next

  _handleResponse: (request, response, next) =>
    return (error, pub) =>
      debug 'got publicKey', { error, gotPublicKey: pub? }
      return response.sendError error if error?
      payload = request.body?.payload
      signature = request.get 'Signature'
      debug 'verifying', { payload, signature }
      return response.sendStatus(401) unless signature?
      return response.sendStatus(401) unless payload?
      verified = @_verifySignature payload, signature, pub
      debug 'is', { verified }
      return response.sendStatus(401) unless verified
      next()

  _verifySignature: (payload, signature, pub) =>
    verify = crypto.createVerify 'SHA1'
    verify.update payload
    return verify.verify pub, signature, 'base64'

  _getOrgPublicKey: (callback) =>
    return callback null, @_orgPublicKey if @_orgPublicKey?
    options =
      uri: TRAVIS_ORG_URI
      json: true
    request.get options, (error, response, body) =>
      return callback error if error?
      return callback body if response.statusCode > 299
      @_orgPublicKey = body?.config?.notifications?.webhook?.public_key
      callback null, @_orgPublicKey

  _getProPublicKey: (callback) =>
    return callback null, @_proPublicKey if @_proPublicKey?
    options =
      uri: TRAVIS_PRO_URI
      json: true
    request.get options, (error, response, body) =>
      return callback error if error?
      return callback body if response.statusCode > 299
      @_proPublicKey = body?.config?.notifications?.webhook?.public_key
      callback null, @_proPublicKey

module.exports = TravisAuthService
