_ = require 'lodash'

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

  delete: ({ owner_name, repo_name, tag }, callback) =>
    record = {
      owner_name
      repo_name
      docker_url: "#{owner_name}/#{repo_name}:#{tag}"
    }

    @datastore.remove record, {multi:true}, callback

  getByTag: ({ owner_name, repo_name, tag, tags }, callback) =>
    tags = tags?.split /,/
    tags = [tags] unless _.isArray tags
    query =
      $query: {
        owner_name
        repo_name
        tag
      }

    query.$query.tags = $all: tags unless _.isEmpty tags

    @datastore.findOne query, {'_id': false}, (error, record) =>
      return callback error if error?
      return callback @_createError 404, 'Deployment Not Found' unless record?
      callback null, record

  getLatest: ({ owner_name, repo_name, tags }, callback) =>
    tags = tags?.split /,/
    tags = [tags] unless _.isArray tags
    query =
      docker_url:
        $exists: true
      ci_passing: true
      owner_name: owner_name
      repo_name: repo_name

    query.tags = $all: tags unless _.isEmpty tags

    @datastore.find(query, _id: false).sort(created_at: -1).limit 1, (error, records) =>
      return callback error if error?
      return callback @_createError 404, 'Deployment Not Found' if _.isEmpty records
      callback null, _.first(records)

  update: ({ docker_url, owner_name, repo_name, tag }, callback) =>
    query = {
      owner_name
      repo_name
      tag
    }
    @datastore.count query, (error, count) =>
      return callback error if error?
      return callback @_createError 404, 'Deployment Not Found' if count == 0
      return callback @_createError 417, 'Multiple deployments found' if count > 1
      @datastore.update query, { $set: { docker_url } }, callback

  addTag: ({ owner_name, repo_name, tag, tagName }, callback) =>
    query = {
      owner_name
      repo_name
      tag
    }
    @datastore.count query, (error, count) =>
      return callback error if error?
      return callback @_createError 404, 'Deployment Not Found' if count == 0
      return callback @_createError 417, 'Multiple deployments found' if count > 1
      @datastore.update query, { $addToSet: { 'tags': tagName.toLowerCase() } }, callback

  _createError: (code, message) =>
    error = new Error message
    error.code = code if code?
    return error

module.exports = DeploymentService
