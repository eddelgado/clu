# Description:
#   A way to interact with the Google Images API.
#
# Commands:
#   hubot image me <query> - The Original. Queries Google Images for <query> and returns a random top result.
#   hubot animate me <query> - The same thing as `image me`, except adds a few parameters to try to return an animated GIF instead.
#   hubot mustache me <url> - Adds a mustache to the specified URL.
#   hubot mustache me <query> - Searches Google Images for the specified query and mustaches it.

googleApiKey = process.env.GOOGLE_API_KEY || ''
googleSearchEngineId = process.env.GOOGLE_SEARCH_ENGINE_ID || ''
googleSafetyLevel = process.env.GOOGLE_SAFETY_LEVEL || 'medium'

module.exports = (robot) ->
  robot.respond /(image|img)( me)? (.*)/i, (msg) ->
    imageMe msg, msg.match[3], (url) ->
      msg.send url

  robot.respond /animate( me)? (.*)/i, (msg) ->
    imageMe msg, msg.match[2], true, (url) ->
      msg.send url

  robot.respond /(?:mo?u)?sta(?:s|c)he?(?: me)? (.*)/i, (msg) ->
    type = Math.floor(Math.random() * 6)
    mustachify = "http://mustachify.me/#{type}?src="
    imagery = msg.match[1]

    if imagery.match /^https?:\/\//i
      msg.send "#{mustachify}#{imagery}"
    else
      imageMe msg, imagery, false, true, (url) ->
        msg.send "#{mustachify}#{url}"

imageMe = (msg, query, animated, faces, cb) ->
  cb = animated if typeof animated == 'function'
  cb = faces if typeof faces == 'function'
  q = v: '1.0', rsz: '8', q: query, safe: 'active'
  q.imgtype = 'animated' if typeof animated is 'boolean' and animated is true
  q.imgtype = 'face' if typeof faces is 'boolean' and faces is true
  #
  msg.http('https://www.googleapis.com/customsearch/v1?cx=ID&key=KEY&q=QUERY&safe=medium')
    .query(
      cx: googleSearchEngineId
      key: googleApiKey
      q: query
      safe: googleSafetyLevel
      searchType: 'image'
    )
    .get() (err, res, body) ->
      if err
        cb "Oh no, an error: #{err}"
      response = JSON.parse(body)
      console.log response
      items = response.items
      if items?.length > 0
        image = msg.random items
        cb "#{image.link}"
      else
        cb 'Hmm, no images. :('
