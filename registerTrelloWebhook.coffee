#!/usr/bin/env coffee

request = require('request-json')
client = request.newClient('https://trello.com/');

key = "404433397f3c0a94c4f8f03ad3425271"
token = "34f3330d2269d5818d2e06279d9dc63ef9157c4ccc4b59ed8cb1f400f14ad2d9"

data =
  description: "GLG Trello webhook"
  callbackURL: "http://clubot.herokuapp.com/trelloCallbacks/"
  idModel: "52e91a4068f467605676a4f1"

client.post "/1/tokens/#{token}/webhooks/?key=#{key}", data, (err, res, body) ->
  console.log err
  console.log body
  return console.log(res.statusCode);
