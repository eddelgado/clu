# Description:
#   Return GLG information about a user from their email address. Requires auth
#   account for epiquery from outside, since this is coming from Heroku.
#   Set the environment variables as they should appear in basic auth.
#
# Commands:
#   hubot whois <user email> - return user info
#
# Configuration:
#   EPIQUERY_HOST
#   EPIQUERY_USER
#   EPIQUERY_PASS
#
# Examples:
#   hubot whois drhayes
#   hubot whois drhayes@glgroup.com

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

  robot.respond /whois ([\w .\-]+)\?*$/i, (msg) ->
    email = msg.match[1]
    if email.indexOf('@') == -1
      email = "#{email}@glgroup.com"

    robot.http(host)
      .path('person/getUserByEmail.mustache')
      .query('Email', email)
      .auth(user, pass)
      .get() (err, resp, body) ->
        response = JSON.parse body
        if !response.length
          msg.reply '''Hmm, couldn't find anyone with that email address.'''
          return
        body = response[0]
        firstname = body.rmFirstName
        lastname = body.rmLastName
        id = body.rmId
        phoneExtension = body.rmExtension
        city = body.rmCity
        state = body.rmState
        msg.reply "You're looking for #{firstname} #{lastname} (#{id}) of #{city}, #{state}. Their extension is #{phoneExtension}."
