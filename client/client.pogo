plastiq = require 'plastiq'
h = plastiq.html

model = {}

auth = require './auth'
auth.attach (model)

if (model.authenticated)
  freeagent = require './freeagent'
  client = freeagent.connect (model.accessToken, auth.signOut)!
  calendar = (require './calendar')(model, client)
  renderAuthenticated (model) = calendar.render (h, model)
  plastiq.attach (document.body, renderAuthenticated, model)
else
  renderUnauthenticated (model) = h 'a.login' { href = '/auth/freeagent' } 'Login with FreeAgent'
  plastiq.attach (document.body, renderUnauthenticated, model)
