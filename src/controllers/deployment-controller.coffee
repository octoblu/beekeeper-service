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
    { tags } = req.query

    @deploymentService.getByTag { owner_name, repo_name, tag, tags }, (error, deployment) =>
      return res.sendError(error) if error?
      res.status(200).send(deployment)

  getLatest: (req, res) =>
    { owner_name, repo_name } = req.params
    { tags } = req.query

    @deploymentService.getLatest { owner_name, repo_name, tags }, (error, deployment) =>
      return res.sendError(error) if error?
      res.status(200).send(deployment)

  addTag: (req, res) =>
    { owner_name, repo_name, tag } = req.params
    { tagName } = req.body
    return res.status(422).send error: 'Missing tagName in body' unless tagName?
    @deploymentService.addTag { owner_name, repo_name, tag, tagName }, (error) =>
      return res.sendError(error) if error?
      res.sendStatus(204)

  update: (req, res) =>
    { owner_name, repo_name, tag } = req.params
    { docker_url } = req.body
    return res.status(422).send error: 'Missing docker_url in body' unless docker_url?
    @deploymentService.update { owner_name, repo_name, tag, docker_url }, (error) =>
      return res.sendError(error) if error?
      res.sendStatus(204)

module.exports = DeploymentController
