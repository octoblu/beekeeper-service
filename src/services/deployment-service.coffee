class DeploymentService
  constructor: ({@db}) ->
    @datastore = @db.deployments

  getLatest: ({ owner_name, repo_name }, callback) =>
    query =
      $query: {
        docker_url:
          $exists: true
        ci_passing: true
        owner_name
        repo_name
      }
      $orderby:
        created_at: -1

    @datastore.findOne query, {'_id': false}, (error, record) =>
      return callback error if error?
      return callback @_createError 404, 'Deployment Not Found' unless record?
      callback null, record

  _createError: (code, message) =>
    error = new Error message
    error.code = code if code?
    return error

module.exports = DeploymentService
