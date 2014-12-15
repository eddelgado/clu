# Description:
#   Periodically check on Mosaic import's health.
#
# Commands:
#   check mosaic
#   check mosaic import <~~ same thing as "check mosaic"

Promise = require('bluebird')

mosaicRoomId = process.env.MOSAIC_ROOM_ID
mosaicImportCron = process.env.MOSAIC_IMPORT_CRON or '0 10 * * *'
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

  errorHandler = (msg) ->
    (err) ->
      robot.logger.error "#{msg}: #{err}"
      null

  # TODO: Use something like (I imagine) bluebird to clean this all up.
  # TODO: New Mosaic?
  # TODO: Stats from a running import?
  checkImport = (say) ->
    say 'Checking in on the Mosaic import.'
    checkImport = Promise.promisify(solrHttp.scope('people/dataimport').query('command', 'status').get(), solrHttp)
    checkImport().then ([resp, body]) ->
      response = JSON.parse body
      if response.status is 'busy'
        say 'Import is running.'
        response
      else if response.status is 'idle'
        say 'Looks like the Solr import is idle.'
      else
        say "Import is #{response.status}."
    .catch(errorHandler('Error checking Mosaic import status'))
    .then (response) ->
      return if not response
      say "Import has been running for #{response.statusMessages?['Time Elapsed']}."
      processed = numeral(response.statusMessages?['Total Documents Processed']).format('0,0')
      skipped = numeral(response.statusMessages?['Total Documents Skipped']).format('0,0')
      say "Import has processed #{processed} records so far and skipped #{skipped}."

    checkCores = Promise.promisify(solrHttp.scope('admin/cores').query('action', 'status').get(), solrHttp)
    checkCores().then ([resp, body]) ->
      response = JSON.parse body
      numPeople = response?.status?.people?.index?.numDocs
      numProjects = response?.status?.projects?.index?.numDocs
      numProjectParticipants = response?.status?['project-participants']?.index?.numDocs
      say 'Here are the stats:',
        "People: #{numeral(numPeople).format('0,0')}",
        "Projects: #{numeral(numProjects).format('0,0')}",
        "Project participants: #{numeral(numProjectParticipants).format('0,0')}"
    .catch(errorHandler('Error checking Mosaic core status'))

  robot.respond /check mosaic( import)?/i, (msg) ->
    checkImport(msg.send.bind(msg))

  new CronJob mosaicImportCron, ->
    checkImport(sayMosaic)
