# Description:
#   Do "funny" robot stuff in response to things it hears.
#
# Commands:
#   (compliance)
#
# Examples:
#   (compliance)

module.exports = (robot) ->

  # robot.hear /\b((?:cm)|(?:project)|(?:client))[#|:|\s](\d+)\b/i, (msg) ->
  robot.hear /\b(compliance)\b/i, (msg) ->
    msg.send 'https://s3.amazonaws.com/uploads.hipchat.com/34193/1366674/z1N3Vhl5LPF2WFD/upload.png'

  robot.hear /\bboop\b/i, (msg) ->
    msg.send 'beep'
