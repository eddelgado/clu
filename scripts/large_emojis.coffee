# Description:
#   Do "funny" robot stuff in response to things it hears.
#
# Commands:
#   (compliance)
#   (worksforme)
#   (worksonmymachine)
#   (omgpopcorn)
#
# Examples:
#   (compliance)
#   (worksforme)
#   (worksonmymachine)
#   (omgpopcorn)

module.exports = (robot) ->

  robot.hear /\(compliance\)/i, (msg) ->
    msg.send 'https://s3.amazonaws.com/uploads.hipchat.com/34193/1366674/z1N3Vhl5LPF2WFD/upload.png'

  robot.hear /\(worksforme\)/i, (msg) ->
    msg.send 'https://s3.amazonaws.com/uploads.hipchat.com/34193/575391/uTasNrS4pQZXwTD/upload.png'

  robot.hear /\(worksonmymachine\)/i, (msg) ->
    msg.send 'https://s3.amazonaws.com/uploads.hipchat.com/34193/575391/uTasNrS4pQZXwTD/upload.png'

  robot.hear /\(omgpopcorn\)/i, (msg) ->
    msg.send 'https://s3.amazonaws.com/uploads.hipchat.com/34193/1077228/m2hKpuwI5gaMBUh/popcorn.jpg'
