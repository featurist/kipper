cookie = require 'cookie-cutter'

queryStringParam (name) =
  match = RegExp('[?&]' + name + '=([^&]*)').exec(window.location.search)
  match @and decodeURIComponent(match.1.replace(r/\+/g, ' '))

token = queryStringParam 'accessToken'

if (token :: String)
  cookie.set('accessToken', token)
  window.location.replace '/'
else
  exports.token = cookie.get 'accessToken'
