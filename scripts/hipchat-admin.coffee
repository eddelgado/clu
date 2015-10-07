# Description
#   Change admin of the Hipchat room.
#
# Commands:
#   hubot steal admin - Change admin of current room to asking user.
#

Promise = require('bluebird')
roomCache = {}

# I am the last person to touch this - but, I don't get along with coffee
# and I'm using this pointless project to understand coffee better'er.  With
# that said, ..if you are reading this in horror.. I don't know what I'm doing
# Signed, Benjamin Hudgens

doGetRoomDetails = (roomId) ->
  new Promise (resolve, reject) ->
    robot.http("https://api.hipchat.com/v2/room/#{roomId}")
      .query('auth_token', AUTH_TOKEN)
      .query('max-results', 1000)
      .get() (err, resp, body) ->
        return reject(err) if err
        response = JSON.parse body
        roomDetails = response.items
        resolve(roomDetails)

doHipchatRoomUnlock = (roomId, robot, msg) ->
  # Grab the info about that room from Hipchat.
  robot.http('https://api.hipchat.com')
    .path("v2/room/#{roomId}")
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
          msg.send "#{msg.message.user.name} is now room owner"

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
    # Use the JID for more accurate matching
    roomJmidFromJabber = msg.envelope.user.reply_to
    if not roomJmidFromJabber
      msg.send 'Get a room first. :)'
      return
    # Find the ID of the room from the lowercase name because Hipchat's stupid
    # API is case-sensitive.
    roomList.then (rooms) ->
      roomJmidFromJabber = roomJmidFromJabber
      c = rooms.length
      while c--
        room = rooms[c]
        if not roomCache[room.id]
          doGetRoomDetails room.id
            .then (details) ->
              roomCache[room.id] = room.xmpp_jid
              if roomCache[room.id] == roomJmidFromJabber
                doHipchatRoomUnlock room.id,robot,msg
        else
          if roomCache[room.id] == roomJmidFromJabber
            doHipchatRoomUnlock room.id,robot,msg
