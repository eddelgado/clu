# Description
#   Change admin of the Hipchat room.
#
# Commands:
#   hubot steal admin - Change admin of current room to asking user.
#

Promise = require('bluebird')
roomCache = {}
roomIdCache = {}

HIPCHAT_AUTH_TOKEN = process.env.HIPCHAT_AUTH_TOKEN
if not HIPCHAT_AUTH_TOKEN
  robot.logger.warning 'The HIPCHAT_AUTH_TOKEN environment variable is not set'
  return

# I am the last person to touch this - but, I don't get along with coffee
# and I'm using this pointless project to understand coffee better'er.  With
# that said, ..if you are reading this in horror.. I don't know what I'm doing
# Signed, Benjamin Hudgens

# In case anyone else comes along, The main complication with this functionality
# is that clu connects through jabber.  When we get a message via jabber we get
# a very limited bit of information about the room.  Currently, the v2 api on
# hipchats REST api does not return the list of rooms with ANY of the meta data
# that corresponds with the information in the jabber informatmion.  Thus, we
# have to query each room individually.  We have so many rooms that we quickly
# reach the threshhold of the hipchat API when trying to get the information
# (jabberID of the room) that we would need to match which room the Request
# came in.
#
# I'm punting on this for now but the easy solution is.. make the user specify
# the room (case sensitive) and use the room name to hit the API.

doGetRoomDetails = (roomId, robot, callback) ->
  console.log "Got to doGetRoomDetails #{roomId}"
  robot.http("https://api.hipchat.com/v2/room/#{roomId}")
    .query('auth_token', HIPCHAT_AUTH_TOKEN)
    .query('max-results', 1000)
    .get() (err, resp, body) ->
      console.log "doGetRoomDetails http", err, resp, body
      return reject(err) if err
      roomDetails = JSON.parse body
      roomIdCache[roomDetails.id] = true
      callback(roomDetails)

doHipchatRoomUnlock = (details, robot, msg) ->
  delete details.created
  delete details.guest_access_url
  delete details.last_active
  delete details.id
  delete details.links
  delete details.participants
  delete details.statistics
  delete details.xmpp_jid
  room.owner =
    id: msg.envelope?.user?.id
  # Send it back!
  robot.http('https://api.hipchat.com')
    .path("v2/room/#{id}")
    .query('auth_token', HIPCHAT_AUTH_TOKEN)
    .put(JSON.stringify(room)) (err, resp, body) ->
      robot.logger.info body
      if err
        robot.logger.error err
        return
      msg.send "#{msg.message.user.name} is now room owner"

module.exports = (robot) ->


  roomList = new Promise (resolve, reject) ->
    robot.http('https://api.hipchat.com/v2/room')
      .query('auth_token', HIPCHAT_AUTH_TOKEN)
      .query('max-results', 1000)
      .get() (err, resp, body) ->
        console.log "RoomList", err, resp, body
        return reject(err) if err
        response = JSON.parse body
        rooms = response.items
        resolve(rooms)

  robot.respond /steal admin/i, (msg) ->
    # Use the JID for more accurate matching
    roomJmidFromJabber = msg.envelope.user.reply_to
    if not roomJmidFromJabber
      return msg.send 'Get a room first. :)'
    # Find the ID of the room from the lowercase name because Hipchat's stupid
    # API is case-sensitive.
    if roomCache[roomJmidFromJabber]
      return doHipchatRoomUnlock roomCache[roomJmidFromJabber], robot, msg

    roomList.then (rooms) ->
      c = rooms.length
      while c--
        room = rooms[c]
        robot = robot
        if not roomIdCache[room.id]
          doGetRoomDetails room.id, robot, (details) ->
            roomCache[details.xmpp_jid] = details
            if details.xmpp_jid == roomJmidFromJabber
              doHipchatRoomUnlock details, robot, msg
