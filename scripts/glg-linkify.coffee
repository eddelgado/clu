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
# Configuration:
#   EPIQUERY_HOST
#   EPIQUERY_USER
#   EPIQUERY_PASS
#
# Examples:
#   cm 12345
#   project#345

module.exports = (robot) ->

  if not process.env.EPIQUERY_HOST
    robot.logger.warning 'The EPIQUERY_HOST environment variable is not set'
    return

  if not process.env.EPIQUERY_USER
    robot.logger.warning 'The EPIQUERY_USER environment variable is not set'
    return

  if not process.env.EPIQUERY_PASS
    robot.logger.warning 'The EPIQUERY_PASS environment variable is not set'
    return

  host = process.env.EPIQUERY_HOST
  user = process.env.EPIQUERY_USER
  pass = process.env.EPIQUERY_PASS

  robot.hear /\b((?:cm)|(?:project))[#|:|\s](\d+)\b/i, (msg) ->
    type = msg.match[1]
    id = msg.match[2]
    return if not type
    return if not id

    type = type.toLowerCase()

    if type is 'cm'
      robot.http(host)
        .path('councilMember/getCouncilMemberByCmId.mustache')
        .query('cmId', id)
        .auth(user, pass)
        .get() (err, resp, body) ->
          return if err
          response = JSON.parse body
          if !response.length
            msg.send '''Hmm, not finding anyone with that CM ID.'''
            return
          body = response[0]
          firstname = body.FIRST_NAME
          lastname = body.LAST_NAME
          msg.send "#{firstname} #{lastname}: https://advisors.glgroup.com/cm/#{id}"

    else if type is 'project'
      robot.http(host)
        .path('pmp/case.mustache')
        .query('pid', id)
        .auth(user, pass)
        .get() (err, resp, body) ->
          return if err
          response = JSON.parse body
          if !response.length
            msg.send '''Hmm, not finding any projects with that ID.'''
            return
          body = response[0]
          title = body.CONSULTATION_TITLE
          rmfirst = body.FIRST_NAME
          rmlast = body.LAST_NAME
          msg.send "#{title} (#{rmfirst} #{rmlast}): https://vega.glgroup.com/Consult/mms/ManageConsultation.aspx?RID=#{id}"
