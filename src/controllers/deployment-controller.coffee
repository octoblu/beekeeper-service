class DeploymentController
  constructor: ({ @deploymentService }) ->
    throw new Error 'Missing deploymentService' unless @deploymentService?

  getLatest: (req, res) =>
    { owner_name, repo_name } = req.params

    @deploymentService.getLatest { owner_name, repo_name }, (error, deployment) =>
      return res.sendError(error) if error?
      res.status(200).send(deployment)

module.exports = DeploymentController
