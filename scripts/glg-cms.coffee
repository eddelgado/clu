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

inspect = require('util').inspect

module.exports = (robot) ->
  robot.hear /\bcm[:|#|\s]?(\d+)\b/i, (msg) ->
    id = msg.match[1]
    return if not id
    msg.send "https://advisors.glgroup.com/cm/#{id}"
