# Description:
#   Webhooks for Trello

module.exports = (robot) ->
  robot.router.post '/trelloCallbacks/', (req, res) ->
    data   = req.body
    room   = "34193_firehose@conf.hipchat.com"

    robot.messageRoom room, "Trello Callback Received: #{ JSON.stringify data }"

    res.send 'OK'
