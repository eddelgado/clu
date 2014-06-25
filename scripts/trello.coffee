# Description:
#   Webhooks for Trello

module.exports = (robot) ->

  # Trello hits the callback with a head to verify it's existance before creating...
  robot.router.head '/trelloCallbacks', (req, res) ->
    console.log "head request"
    res.send 200

  # Receive callback for events on the GLG Projects board
  robot.router.post '/trelloCallbacks', (req, res) ->
    console.log req.body
    data   = req.body
    room   = "34193_firehose@conf.hipchat.com"

    # do something interesting wit these events...
    robot.messageRoom room, "Trello Callback Received: #{ JSON.stringify data }"

    res.send 200
