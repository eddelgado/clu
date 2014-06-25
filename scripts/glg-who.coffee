# Description:
#   Return GLG information about a user from their email address.
#
# Commands:
#   hubot who is drhayes@glgroup.com - return user info
#
# Examples:
#   hubot who is drhayes@glgroup.com?
#   hubot who is drhayes

module.exports = (robot) ->

  robot.respond /who is ([\w .\-]+)\?*$/i, (msg) ->
    msg.reply 'Some coder.'
