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
    robot.logger.info asString
    msg.send "/code #{asString}"
    msg.send 'Sent.'
