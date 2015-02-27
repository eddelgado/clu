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
    console.dir(msg);
    robot.logger.info(JSON.stringify(msg))
    msg.send "Room is #{msg.envelope.room}"

  robot.respond /debug user/i, (msg) ->
    console.dir(msg);
    robot.logger.info(JSON.stringify(msg))
    msg.send "User is #{user}"

  robot.respond /^say(.*)/i, (msg) ->
    what = msg.match[1]
    msg.send "#{{what}}"
