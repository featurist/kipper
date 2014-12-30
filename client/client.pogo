auth = require './auth'
plastiq = require 'plastiq'
h = plastiq.html

render (model) =
  h 'div' "accessToken = #(model.accessToken)"

model = {
  accessToken = auth.token
}

plastiq.attach (document.body, render, model)
