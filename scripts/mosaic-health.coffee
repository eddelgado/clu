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

  # TODO: New Mosaic?
  checkImport = (say) ->
    say 'Checking in on the Mosaic import.'
    getImports = Promise.promisify(solrHttp.scope('people/dataimport').query('command', 'status').get(), solrHttp)().then ([resp, body]) ->
      response = JSON.parse body
      result =
        status: response.status
      if response.status is 'busy'
        result.elapsed = response.statusMessages?['Time Elapsed']
        result.processed = response.statusMessages?['Total Documents Processed']
        result.skipped = response.statusMessages?['Total Documents Skipped']
      result
    .catch(errorHandler('Error checking Mosaic import status'))

    getCores = Promise.promisify(solrHttp.scope('admin/cores').query('action', 'status').get(), solrHttp)().then ([resp, body]) ->
      response = JSON.parse body
      result =
        people: response?.status?.people?.index?.numDocs
        projects: response?.status?.projects?.index?.numDocs
        projectParticipants: response?.status?['project-participants']?.index?.numDocs
    .catch(errorHandler('Error checking Mosaic core status'))

    Promise.join getImports, getCores, (importResponse, coresResponse) ->
      msgs = []
      if importResponse.status is 'idle'
        msgs.push 'The import is idle.'
      else if importResponse.status is 'busy'
        msgs.push 'The import is running right now.'
        msgs.push "Import has been running for #{importResponse.elapsed}."
        processed = numeral(importResponse.processed).format('0,0')
        skipped = numeral(importResponse.skipped).format('0,0')
        msgs.push "Import has processed #{processed} records so far and skipped #{skipped}."
      else
        msgs.push "The import is #{importResponse.status}"
      if coresResponse
        msgs.push 'Core stats:'
        msgs.push "People: #{numeral(coresResponse.people).format('0,0')}"
        msgs.push "Projects: #{numeral(coresResponse.projects).format('0,0')}"
        msgs.push "Project participants: #{numeral(coresResponse.projectParticipants).format('0,0')}"
      # Tell the world!
      say.apply null, msgs

  robot.respond /check mosaic( import)?/i, (msg) ->
    checkImport(msg.send.bind(msg))

  new CronJob mosaicImportCron, ->
    checkImport(sayMosaic)
