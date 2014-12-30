users = {}

module.exports = {
  findOrCreate (data, done) =
    user = users.(data.accessToken)
    if (user)
      done (nil, user)
    else
      users.(data.accessToken) = data
      done (nil, data)
}