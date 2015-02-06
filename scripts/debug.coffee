# Description
#   Echo the msg object back.
#
# Commands:
#   hubot debug msg - Echo back the "msg" object.
#

CircularJSON = require('circular-json')

module.exports = (robot) ->
  robot.respond /debug msg/i, (msg) ->
    asString = CircularJSON.stringify(msg)
    msg.send "/code #{asString}"
