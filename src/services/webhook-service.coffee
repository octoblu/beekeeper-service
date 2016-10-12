class WebhookService
  constructor: ({@redis}) ->

  create: ({type, owner_name, repo_name, body}, callback) =>
    data = JSON.stringify { type, body, owner_name, repo_name }
    @redis.lpush 'webhooks', data, callback

  _createError: (code, message) =>
    error = new Error message
    error.code = code if code?
    return error

module.exports = WebhookService
