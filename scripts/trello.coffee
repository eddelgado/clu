# Description:
#   Webhooks for Trello

module.exports = (robot) ->
  robot.router.post '/trelloCallbacks/:room', (req, res) ->
    data   = req.body
    room   = req.params.room

    robot.messageRoom room, "Trello Callback Received: #{ JSON.stringify data }"

    res.send 'OK'
