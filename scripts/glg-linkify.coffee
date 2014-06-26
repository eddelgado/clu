# Description:
#   Listen for any mentions of CM IDs and return a link to that CM's advisor page.
#   Listen for any mentions of project IDs and return a link to that project page
#   in Vega.
#
# Commands:
#   cm <id>
#   cm:<id>
#   cm#<id>
#   project <id>
#   project:<id>
#   project#<id>
#
# Examples:
#   cm 12345
#   project#345

module.exports = (robot) ->
  console.log 'at all?'
  robot.hear /\b((?:cm)|(?:project))[#|:|\s](\d+)\b/i, (msg) ->
    type = msg.match[1]
    id = msg.match[2]
    return if not type
    return if not id
    if type is 'cm'
      msg.send "https://advisors.glgroup.com/cm/#{id}"
    else if type is 'project'
      msg.send "https://vega.glgroup.com/Consult/mms/ManageConsultation.aspx?RID=#{id}"
