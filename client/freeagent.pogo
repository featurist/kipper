request = require 'superagent'
_ = require 'underscore'

apiUrl (path) =
  if (path.indexOf('https') == 0)
    path
  else
    'https://api.freeagent.com/v2/' + path

exports.connect (accessToken)! =

  tempCache () = {
    promises = {}
    get (path) =
      p = self.promises.(path)
      if (p)
        p
      else
        self.promises.(path) = get (path)
        self.promises.(path)
  }

  get (path) ! =
    request.get(apiUrl(path)) \
           .set('Accept', 'application/json') \
           .set('Authorization', 'Bearer ' + accessToken).end ^!

  freeagent = {
    me () ! =
      response = get 'users/me' !
      self._user = response.body.user
      self._user

    timeslips () ! =
      response = get "timeslips?user=#(self._user.url)&page=1&per_page=50" !
      slips = response.body.timeslips
      cache = tempCache()
      entries = [
        slip <- slips
        {
          timeslip = slip
          project = cache.get(slip.project)!.body.project
          task = cache.get(slip.task)!.body.task
        }
      ]
      _.groupBy (entries) @(e) @{ e.timeslip.dated_on }
  }
  freeagent.me () !
  freeagent
