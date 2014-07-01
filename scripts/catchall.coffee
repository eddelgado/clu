# Description
#   Send all uncaught commands to cleverbot.
#   Based on:
#   https://github.com/github/hubot-scripts/blob/master/src/scripts/cleverbot.coffee
#
# Dependencies:
#   "cleverbot-node": "0.1.1"
#
# Commands:
#   hubot (.*) - If not caught by another script, replies with cleverbot response.
#

cleverbot = require('cleverbot-node')

module.exports = (robot) ->
  bot_sessions = {}

  robot.catchAll (msg) ->
    search = new RegExp("^@?" + robot.name + "(.+)", "i")
    if msg.message.text and msg.message.text.match(search)
        sessionKey = if msg.message.room then msg.message.room else msg.message.user.name
        if not bot_sessions[sessionKey]?
            bot_sessions[sessionKey] = new cleverbot()
        c = bot_sessions[sessionKey]
        replace = new RegExp("^(@?" + robot.name + "[:,]?)", "i")
        data = msg.message.text.trim().replace(replace, '').trim()
        c.write(data, (c) =>
            response = c.message.replace /cleverbot/i, robot.name
            msg.send(response)
        )
