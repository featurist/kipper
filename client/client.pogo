model = {}

auth = require './auth'
auth.attach (model)

freeagent = require './freeagent'
client = freeagent.connect (model.accessToken)!

calendar = (require './calendar')(model, client)

plastiq = require 'plastiq'
h = plastiq.html

render (model) =
  if (model.authenticated)
    calendar.render (h, model)
  else
    h 'a' { href = '/auth/freeagent' } 'Login with FreeAgent'

plastiq.attach (document.body, render, model)
