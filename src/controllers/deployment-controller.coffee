class DeploymentController
  constructor: ({ @deploymentService }) ->
    throw new Error 'Missing deploymentService' unless @deploymentService?

  create: (req, res) =>
    { owner_name, repo_name, tag } = req.params

    @deploymentService.create { owner_name, repo_name, tag }, (error) =>
      return res.sendError(error) if error?
      res.status(201).end()

  delete: (req, res) =>
    { owner_name, repo_name, tag } = req.params

    @deploymentService.delete { owner_name, repo_name, tag }, (error) =>
      return res.sendError(error) if error?
      res.status(204).end()

  getByTag: (req, res) =>
    { owner_name, repo_name, tag } = req.params

    @deploymentService.getByTag { owner_name, repo_name, tag }, (error, deployment) =>
      return res.sendError(error) if error?
      res.status(200).send(deployment)

  getLatest: (req, res) =>
    { owner_name, repo_name } = req.params

    @deploymentService.getLatest { owner_name, repo_name }, (error, deployment) =>
      return res.sendError(error) if error?
      res.status(200).send(deployment)
    
  update: (req, res) =>
    { owner_name, repo_name, tag } = req.params
    { docker_url } = req.body
    return res.status(422).send error: 'Missing docker_url in body' unless docker_url?
    @deploymentService.update { owner_name, repo_name, tag, docker_url }, (error) =>
      return res.sendError(error) if error?
      res.sendStatus(204)

module.exports = DeploymentController
