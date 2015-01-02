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

  post (path, data) ! =
    request.post(apiUrl(path)) \
           .type('json') \
           .send(data) \
           .set('Content-Type', 'application/json') \
           .set('Accept', 'application/json') \
           .set('Authorization', 'Bearer ' + accessToken).end ^!

  freeagent = {
    me () ! =
      response = get 'users/me' !
      self._user = response.body.user
      self._user

    company () ! =
      response = get 'company' !
      response.body.company

    populateTimeslip (slip, cache) ! =
      {
        timeslip = slip
        project = cache.get(slip.project)!.body.project
        task = cache.get(slip.task)!.body.task
      }

    timeslips () ! =
      response = get "timeslips?user=#(self._user.url)&page=1&per_page=50" !
      slips = response.body.timeslips
      cache = tempCache()
      entries = [
        slip <- slips
        self.populateTimeslip (slip, cache) !
      ]
      _.groupBy (entries) @(e) @{ e.timeslip.dated_on }

    projects () ! =
      response = get "projects" !
      projects = response.body.projects
      for each @(project) in (projects)
        project.tasks = get "tasks?project=#(project.url)" !.body.tasks

      _.sortBy(projects, @(p) @{ p.name })

    addTimeslip (details) ! =
      response = post 'timeslips' {
        timeslip = {
          user = self._user.url
          project = details.task.project
          task = details.task.url
          hours = details.hours
          dated_on = details.date
        }
      } !
      cache = tempCache()
      self.populateTimeslip (response.body.timeslip, cache) !

  }
  freeagent.me () !
  freeagent
