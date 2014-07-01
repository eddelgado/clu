# Description
#   Get CLU to poke you when someone comes back online and is available.
#   Provide web endpoints for HipChat webhooks about people entering rooms.

module.exports = (robot) ->

  robot.router.post '/hipchatRoomEnter', (req, res) ->
    data = req.body
    room = "34193_firehose@conf.hipchat.com"

    # do something interesting wit these events...
    robot.messageRoom room, "HipChat room_enter: #{ JSON.stringify data }"
