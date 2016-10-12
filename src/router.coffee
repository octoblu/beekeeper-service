WebhookController = require './controllers/webhook-controller'

class Router
  constructor: ({@webhookService}) ->
    throw new Error 'Missing webhookService' unless @webhookService?

  route: (app) =>
    webhookController = new WebhookController {@webhookService}

    app.post '/webhooks/:type', webhookController.create
    app.post '/webhooks/:type/:owner_name/:repo_name', webhookController.create

module.exports = Router
