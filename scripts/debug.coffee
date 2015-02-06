# Description
#   Echo the msg object back.
#
# Commands:
#   hubot debug msg - Echo back the "msg" object.
#

CircularJSON = require('circular-json')

module.exports = (robot) ->
  # clu is always available.
  robot.adapter?.setAvailability? 'chat'

  robot.respond /debug msg/i, (msg) ->
    for k of msg
      asString = CircularJSON.stringify(msg)
      msg.send "/code #{k}:#{asString}"

  robot.respond /debug room/i, (msg) ->
    msg.send "Room is #{msg.message.room}"

  robot.respond /debug user/i, (msg) ->
    user = CircularJSON.stringify msg.message?.user
    msg.send "User is #{user}"
