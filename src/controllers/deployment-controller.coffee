class DeploymentController
  constructor: ({ @deploymentService }) ->
    throw new Error 'Missing deploymentService' unless @deploymentService?

  create: (req, res) =>
    { owner_name, repo_name, tag } = req.params

    @deploymentService.create { owner_name, repo_name, tag }, (error) =>
      return res.sendError(error) if error?
      res.status(201).end()

  getLatest: (req, res) =>
    { owner_name, repo_name } = req.params

    @deploymentService.getLatest { owner_name, repo_name }, (error, deployment) =>
      return res.sendError(error) if error?
      res.status(200).send(deployment)

module.exports = DeploymentController
