WebhookController = require './controllers/webhook-controller'
DeploymentController = require './controllers/deployment-controller'

class Router
  constructor: ({ @deploymentService, @webhookService }) ->
    throw new Error 'Missing webhookService' unless @webhookService?
    throw new Error 'Missing deploymentService' unless @deploymentService?

  route: (app) =>
    webhookController    = new WebhookController {@webhookService}
    deploymentController = new DeploymentController {@deploymentService}

    app.get '/deployments/:owner_name/:repo_name/latest', deploymentController.getLatest
    app.post '/deployments/:owner_name/:repo_name/:tag', deploymentController.create
    app.get '/deployments/:owner_name/:repo_name/:tag', deploymentController.getByTag

    app.post '/webhooks/:type', webhookController.create
    app.post '/webhooks/:type/:owner_name/:repo_name', webhookController.create

module.exports = Router
