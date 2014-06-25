# Description:
#   Workrooms conferencing assistant
#
# Commands:
#   hubot workroom [name] - Creates a work room, with an optional name, defaults to your name

module.exports = (robot) ->

  robot.respond /workroom( (\w+))?$/i, (msg) ->
    room_name = msg.match[2] ? msg.message.user.name.toLowerCase()
    msg.send "https://workrooms.glgresearch.com/workrooms/#/#{room_name}"
