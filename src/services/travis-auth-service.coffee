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
    payload = request.body?.payload
    signature = request.get 'Signature'
    @_authOrg { payload, signature }, (error, orgVerified) =>
      return response.sendError error if error?
      debug 'orgVerified', orgVerified
      return next() if orgVerified
      @_authPro { payload, signature }, (error, proVerified) =>
        return response.sendError error if error?
        debug 'proVerified', proVerified
        return next() if proVerified
        response.sendStatus(401)

  _authPro: ({ payload, signature }, callback) =>
    debug 'auth pro'
    @_getProPublicKey (error, pub) =>
      return callback error if error?
      @_verify { pub, payload, signature }, callback

  _authOrg: ({ payload, signature }, callback) =>
    debug 'auth org'
    @_getOrgPublicKey (error, pub) =>
      return callback error if error?
      @_verify { pub, payload, signature }, callback

  _verify: ({ pub, payload, signature }, callback) =>
    debug 'got publicKey', { gotPublicKey: pub? }
    debug 'verifying', { payload, signature }
    return callback null, false unless signature?
    return callback null, false unless payload?
    callback null, @_verifySignature payload, signature, pub

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
