express = require 'express'
bodyParser = require 'body-parser'
cookieParser = require 'cookie-parser'
session = require 'express-session'

env = require './env'
users = require './users'
passport = require 'passport'
OAuth2Strategy = require 'passport-oauth'.OAuth2Strategy

findUserForOAuth (accessToken, refreshToken, profile, done) =
  users.findOrCreate {
    accessToken  = accessToken
    refreshToken = refreshToken
    profile      = profile
  } @(err, user)
    done(err, user)

provider = @new OAuth2Strategy {
  authorizationURL = 'https://api.freeagent.com/v2/approve_app'
  tokenURL         = 'https://api.freeagent.com/v2/token_endpoint'
  callbackURL      = 'http://kipper.herokuapp.com/auth/freeagent/callback'
  clientID         = env.FREEAGENT_CLIENT_ID
  clientSecret     = env.FREEAGENT_CLIENT_SECRET
} (findUserForOAuth)

passport.serializeUser @(user, done)
  done (null, user)

passport.deserializeUser @(user, done)
  done (null, user)

passport.use('freeagent', provider)

app = express ()

app.use (cookieParser ())
app.use (bodyParser.urlencoded (extended: false))
app.use (session {
  secret = env.FREEAGENT_CLIENT_SECRET
  resave = false
  saveUninitialized = true
})
app.use (passport.initialize ())
app.use (passport.session ())

app.use @(req, res, next)
  if (req.headers.'x-forwarded-proto' == 'http')
    res.redirect ("https://" + req.headers.host + req.url)
  else
    next ()

app.get '/' @(req, res, next)
  if (req.user)
    res.end (JSON.stringify(req.user))
  else
    res.end '<a href="/auth/freeagent">Login with FreeAgent</a>'

app.get '/auth/freeagent' (passport.authenticate 'freeagent' (scope: 'Time'))

app.get '/auth/freeagent/callback' (
  passport.authenticate 'freeagent' {
    successRedirect = '/auth/freeagent/done'
    failureRedirect = '/login'
  }
)

app.get '/auth/freeagent/done' @(req, res)
  res.redirect "/?accessToken=#(req.user.accessToken)&refreshToken=#(req.user.refreshToken)"

app.use (express.static 'public')

app.listen (process.env.PORT || 3001)
