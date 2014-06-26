# Description:
#   Listen for any mentions of CM IDs and return a link to that CM's advisor page.
#
# Commands:
#   cm <id>
#   cm:<id>
#   cm#<id>
#
# Examples:
#   cm 12345

module.exports = (robot) ->
  robot.hear /cm (\d+)/i, (msg) ->
    msg.respond JSON.stringify(msg)
