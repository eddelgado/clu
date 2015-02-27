# Description
#   Change admin of the Hipchat room.
#
# Commands:
#   hubot steal admin - Change admin of current room to asking user.
#

Promise = require('bluebird')

module.exports = (robot) ->
  AUTH_TOKEN = process.env.HIPCHAT_AUTH_TOKEN
  if not AUTH_TOKEN
    robot.logger.warning 'The HIPCHAT_AUTH_TOKEN environment variable is not set'
    return

  roomList = new Promise (resolve, reject) ->
    robot.http('https://api.hipchat.com/v2/room')
      .query('auth_token', AUTH_TOKEN)
      .query('max-results', 1000)
      .get() (err, resp, body) ->
        return reject(err) if err
        response = JSON.parse body
        rooms = response.items
        resolve(rooms)

  robot.respond /steal admin/i, (msg) ->
    roomName = msg.envelope.room
    if not roomName
      msg.send 'Get a room first. :)'
      return
    # Find the ID of the room from the lowercase name because Hipchat's stupid
    # API is case-sensitive.
    roomList.then (rooms) ->
      console.dir(rooms)
      roomName = roomName.replace("_"," ");
      room = rooms.filter (room) -> room.name.toLowerCase() == roomName.toLowerCase()
      if not room.length
        msg.send '''Couldn't find the room in the room list!'''
        return
      room = room[0]
      id = room.id
      robot.logger.info room
      # Grab the info about that room from Hipchat.
      robot.http('https://api.hipchat.com')
        .path("v2/room/#{id}")
        .query('auth_token', AUTH_TOKEN)
        .get() (err, resp, body) ->
          if err
            robot.logger.error err
            return
          robot.logger.info body
          room = JSON.parse body
          # Re-use the response after cleaning it up a bit
          delete room.created
          delete room.guest_access_url
          delete room.last_active
          delete room.id
          delete room.links
          delete room.participants
          delete room.statistics
          delete room.xmpp_jid
          # Update to make current user the admin.
          console.dir(room)
          room.owner =
            id: msg.envelope?.user?.id
          # Send it back!
          robot.http('https://api.hipchat.com')
            .path("v2/room/#{id}")
            .query('auth_token', AUTH_TOKEN)
            .put(JSON.stringify(room)) (err, resp, body) ->
              robot.logger.info body
              if err
                robot.logger.error err
                return
              msg.send "#{msg.user.name} is now room owner"
