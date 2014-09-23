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
#   client <id>
#   client:<id>
#   client#<id>
#   person <id>
#   person:<id>
#   person#<id>
#
# Configuration:
#   EPIQUERY_HOST
#   EPIQUERY_USER
#   EPIQUERY_PASS
#
# Examples:
#   cm 12345
#   project#345
#   client:567
#   person 789

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

  robot.hear /\b((?:cm)|(?:project)|(?:client)|(?:person))[#|:|\s](\d+)\b/i, (msg) ->
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
            return msg.send '''Hmm, not finding anyone with that CM ID.'''
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
            return msg.send '''Hmm, not finding any projects with that ID.'''
          body = response[0]
          title = body.CONSULTATION_TITLE
          rmfirst = body.FIRST_NAME
          rmlast = body.LAST_NAME
          msg.send "#{title} (#{rmfirst} #{rmlast}): https://vega.glgroup.com/Consult/mms/ManageConsultation.aspx?RID=#{id}"

    else if type is 'client'
      robot.http('https://compliance.glgroup.com/')
        .path("/api/clientconfig/#{id}")
        .auth(user, pass)
        .get() (err, resp, body) ->
          return if err
          response = JSON.parse body
          if !response
            return msg.send 'Hmm, not finding any client with that ID.'
          if response.errors
            return msg.send "Uh oh, errors: #{response.errors}"
          body = response[0]
          name = response.client.name
          msg.send "#{name}: https://compliance.glgroup.com/api/clientconfig/#{id}"

    else if type is 'person'
      robot.http(host)
        .path('person/getPersonByPersonID.mustache')
        .query('PersonID', id)
        .auth(user, pass)
        .get() (err, resp, body) ->
          return if err
          response = JSON.parse body
          if !response
            return msg.send 'Hmm, not finding any person with that ID.'
          if response.errors
            return msg.send "Uh oh, errors: #{response.errors}"
          body = response[0]
          name = "#{body.FIRST_NAME} #{body.LAST_NAME}"
          msg.send "Person #{id} is #{name}."
