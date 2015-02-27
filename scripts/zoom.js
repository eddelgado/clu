// Description
//   Get a zoom meeting room link
//
// Commands:
//   clu zoom - Respond with a zoom meeting url
//   clu meeting - Respond with a zoom meeting url
//   start a meeting - Respond with a zoom meeting url
//   start a zoom - Respond with a zoom meeting url
//   zoom me - Respond with a zoom meeting url

var qs = require('querystring');
var https = require('https');

if (!process.env.ZOOM_USER) {
  robot.logger.warning("Missing Environment Variable: ZOOM_USER");
  return;
}
if (!process.env.ZOOM_PASS) {
  robot.logger.warning("Missing Environment Variable: ZOOM_PASS");
  return;
}
if (!process.env.ZOOM_HOST) {
  robot.logger.warning("Missing Environment Variable: ZOOM_HOST");
  return;
}

module.exports = function(robot) {

  robot.respond(/(zoom|meeting)/i, function(msg) {
    doGetZoomMeeting(function(zoomUrl) {
      msg.send(zoomUrl);
    })
  });

  robot.hear(/(start a meeting|start a zoom|zoom me|^zoom$)/i, function(msg) {
    doGetZoomMeeting(function(zoomUrl) {
      msg.send(zoomUrl);
    })
  });

  var doGetZoomMeeting = function doGetZoomMeeting(cb) {

    // Assign these environment vars (for readability)
    var apiKey = process.env.ZOOM_USER;
    var apiSecret = process.env.ZOOM_PASS;
    var hostId = process.env.ZOOM_HOST;

    var zoomOptions = {
      api_key: apiKey,
      api_secret: apiSecret,
      data_type: "JSON",
      host_id: hostId,
      topic: "Clu Bot Meeting",
      type: 3,
      option_jbh: true
    };

    var options = {
      host: "api.zoom.us",
      path: "/v1/meeting/create",
      method: "POST",
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'accept': 'application/json'
      }
    };

    var request = https.request(options, function(response) {
      var _buffer = "";
      // Handle response
      response.on('data', function doHandleDataReceived(data) {
        _buffer += data;
      });

      response.on('end', function doHandleRequestEnded() {
        try {
          var response = JSON.parse(_buffer);
          console.dir(response);
          cb(response.join_url);
        } catch (Exception) {
          robot.logger.info("Could not parse response:" + _buffer);
        }
      });

    });

    request.write(qs.stringify(zoomOptions));
    request.end();

  }

}
