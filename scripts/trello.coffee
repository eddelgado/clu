# Description:
#   Webhooks for Trello

module.exports = (robot) ->
  robot.router.head '/trelloCallbacks', (req, res) ->
    console.log "head request"
    res.send 200

  robot.router.post '/trelloCallbacks', (req, res) ->
    console.log req.body
    data   = req.body
    room   = "34193_firehose@conf.hipchat.com"

    robot.messageRoom room, "Trello Callback Received: #{ JSON.stringify data }"

    res.send 200
