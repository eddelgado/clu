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

  robot.respond /debug room/i, (msg) ->
    msg.send "Room is #{msg.envelope.room}"

  robot.respond /debug user/i, (msg) ->
    user = CircularJSON.stringify msg.envelope?.user
    msg.send "User is #{user}"
