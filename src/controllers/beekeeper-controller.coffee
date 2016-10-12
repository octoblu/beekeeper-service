class BeekeeperController
  constructor: ({@beekeeperService}) ->
    throw new Error 'Missing beekeeperService' unless @beekeeperService?

  hello: (request, response) =>
    {hasError} = request.query
    @beekeeperService.doHello {hasError}, (error) =>
      return response.sendError(error) if error?
      response.sendStatus(200)

module.exports = BeekeeperController
