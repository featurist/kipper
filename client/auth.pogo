cookie = require 'cookie-cutter'

authenticated = false

queryStringParam (name) =
  match = RegExp('[?&]' + name + '=([^&]*)').exec(window.location.search)
  match @and decodeURIComponent(match.1.replace(r/\+/g, ' '))

accessToken = queryStringParam 'accessToken'

if (accessToken :: String)
  cookie.set('accessToken', accessToken)
  window.location.replace '/'
else
  accessToken := cookie.get 'accessToken'
  authenticated := (accessToken :: String)

exports.attach (model) =
  model.authenticated = authenticated
  model.accessToken = accessToken

exports.signOut() =
  cookie.set('accessToken', '', { expires = @new Date(0) })
  window.location.replace '/'
