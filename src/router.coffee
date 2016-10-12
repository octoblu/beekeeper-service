BeekeeperController = require './controllers/beekeeper-controller'

class Router
  constructor: ({@beekeeperService}) ->
    throw new Error 'Missing beekeeperService' unless @beekeeperService?

  route: (app) =>
    beekeeperController = new BeekeeperController {@beekeeperService}

    app.get '/hello', beekeeperController.hello
    # e.g. app.put '/resource/:id', someController.update

module.exports = Router
