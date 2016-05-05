# Description:
#   Do "funny" robot stuff in response to things it hears.
#
# Commands:
#   (compliance)
#   (worksforme)
#
# Examples:
#   (compliance)
#   (worksforme)

module.exports = (robot) ->

  robot.hear /\b\(compliance\)\b/i, (msg) ->
    msg.send 'https://s3.amazonaws.com/uploads.hipchat.com/34193/1366674/z1N3Vhl5LPF2WFD/upload.png'

  robot.hear /\b\(worksforme\)\b/i, (msg) ->
    msg.send 'https://s3.amazonaws.com/uploads.hipchat.com/34193/575391/uTasNrS4pQZXwTD/upload.png'
