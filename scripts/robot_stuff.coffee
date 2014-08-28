# Description:
#   Do "funny" robot stuff in response to things it hears.
#
# Commands:
#   beep
#
# Examples:
#   beep

module.exports = (robot) ->

  # robot.hear /\b((?:cm)|(?:project)|(?:client))[#|:|\s](\d+)\b/i, (msg) ->
  robot.hear /\bbeep\b/i, (msg) ->
    msg.send 'boop'

  robot.hear /\bboop\b/i, (msg) ->
    msg.send 'beep'
