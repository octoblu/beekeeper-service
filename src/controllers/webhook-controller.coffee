class WebhookController
  constructor: ({@webhookService}) ->
    throw new Error 'Missing webhookService' unless @webhookService?

  create: (req, res) =>
    { type, owner_name, repo_name } = req.params
    body = req.body
    if body.payload?
      try
        body = JSON.parse body.payload
      catch error
        console.error error

    @webhookService.create { type, body, owner_name, repo_name }, (error) =>
      return res.sendError(error) if error?
      res.status(201).end()

module.exports = WebhookController
