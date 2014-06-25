# Description:
#   Webhooks for Trello

module.exports = (robot) ->
  robot.router.post '/hubot/trelloCallbacks/:room', (req, res) ->
    data   = JSON.parse req.body.payload
    room = req.params.room

    robot.messageRoom room, "Trello Callback Received"

    res.send 'OK'
