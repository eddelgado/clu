# Description:
#   Workrooms conferencing assistant
#
# Commands:
#   hubot workroom [name] - Creates a work room, with an optional name, defaults to your name

module.exports = (robot) ->

  robot.hear /globaltest/i, (msg) ->
    msg.send "I heard you"

  robot.respond /workroom( (\w+))?$/i, (msg) ->
    room_name = msg.match[2] ? msg.message.user.name.toLowerCase()
    room_name = room_name.replace /\s/g, "_"
    msg.send "https://workrooms.glgresearch.com/workrooms/#/#{room_name}"
