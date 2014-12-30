keys = ['FREEAGENT_CLIENT_ID', 'FREEAGENT_CLIENT_SECRET']

localEnv (key) =
  if (@not (localEnv.json :: Object))
    try
      localEnv.json = require './env.json'
    catch (e)
      throw (@new Error "No key #(key) in process.env or ./env.json")

  value = localEnv.json.(key)
  if (value :: String)
    value
  else
    throw (@new Error ("requires env.#(key)"))

values = {}
keys.forEach @(key)
  values.(key) = process.env.(key) @or localEnv(key)

module.exports = values
