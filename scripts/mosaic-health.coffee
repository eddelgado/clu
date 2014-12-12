# Description:
#   Periodically check on Mosaic import's health.

module.exports = (robot) ->
  robot.respond /mosaic test/i, (msg) ->
    robot.messageRoom '34193_mosaic@conf.hipchat.com', 'A test Mosaic message'
