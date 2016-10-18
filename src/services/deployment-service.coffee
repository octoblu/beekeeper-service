class DeploymentService
  constructor: ({ @db, @redis }) ->
    @datastore = @db.deployments

  create: ({ owner_name, repo_name, tag }, callback) =>
    record = {
      created_at: new Date()
      owner_name
      repo_name
      tag
    }

    @datastore.insert record, (error) =>
      return callback error if error?
      type = 'deployment:create'
      body = {
        owner_name
        repo_name
        tag
      }

      data = JSON.stringify { type, body, owner_name, repo_name }
      @redis.lpush 'webhooks', data, callback

  getByTag: ({ owner_name, repo_name, tag }, callback) =>
    query =
      $query: {
        owner_name
        repo_name
        tag
      }

    @datastore.findOne query, {'_id': false}, (error, record) =>
      return callback error if error?
      return callback @_createError 404, 'Deployment Not Found' unless record?
      callback null, record

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
