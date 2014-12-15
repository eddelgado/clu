# Description:
#   Periodically check on Mosaic import's health.
#
# Commands:
#   check mosaic
#   check mosaic import <~~ same thing as "check mosaic"


mosaicRoomId = process.env.MOSAIC_ROOM_ID
mosaicImportCron = process.env.MOSAIC_IMPORT_CRON or '0 10 * * *'
# Give the URL of the dataimport command on the core we care about.
solrHost = process.env.SOLR_HOST
solrUser = process.env.SOLR_USER
solrPass = process.env.SOLR_PASS

CronJob = require('cron').CronJob
numeral = require('numeral')

module.exports = (robot) ->
  if not mosaicRoomId
    robot.logger.warning 'The MOSAIC_ROOM_ID environment variable is not set'
    return

  if not solrHost
    robot.logger.warning 'The SOLR_HOST environment variable is not set'
    return

  if not solrUser
    robot.logger.warning 'The SOLR_USER environment variable is not set'
    return

  if not solrPass
    robot.logger.warning 'The SOLR_PASS environment variable is not set'
    return

  sayMosaic = (msgs...) ->
    robot.messageRoom mosaicRoomId, msgs...

  # This stuff is the same no matter how often we go there, save it.
  solrHttp = robot.http(solrHost)
    .query('wt', 'json')
    .auth(solrUser, solrPass)

  # TODO: Use something like (I imagine) bluebird to clean this all up.
  checkImport = (say) ->
    say 'Checking in on the Mosaic import.'
    solrHttp.scope('people/dataimport')
      .query('command', 'status')
      .get() (err, resp, body) ->
        if err
          robot.logger.error "Error checking Mosaic import status: #{err}"
          return
        response = JSON.parse body
        if response.status isnt 'idle'
          say "Import status is #{response.status}."
          return

        say 'Looks like the Solr import is idle. Checking cores...'
        solrHttp.scope('admin/cores')
          .query('action', 'STATUS')
          .get() (err, resp, body) ->
            if err
              robot.logger.error "Error checking Mosaic core status: #{err}"
              return
            response = JSON.parse body
            numPeople = response?.status?.people?.index?.numDocs
            numProjects = response?.status?.projects?.index?.numDocs
            numProjectParticipants = response?.status?['project-participants']?.index?.numDocs
            say 'Here are the stats:',
              "People: #{numeral(numPeople).format('0,0')}",
              "Projects: #{numeral(numProjects).format('0,0')}",
              "Project participants: #{numeral(numProjectParticipants).format('0,0')}"

  robot.respond /check mosaic( import)?/i, (msg) ->
    checkImport(msg.send.bind(msg))

  new CronJob mosaicImportCron, ->
    checkImport(sayMosaic)
