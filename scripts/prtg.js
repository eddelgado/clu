// Description
//   Respond to PRTG notices with more information
//
// Commands:
//   <location> cerca - lastrun (Down)

var https = require('https');
var querystring = require('querystring');
var cercaLastRunHealthcheckUrl = '/cerca-indexer-3D9FA02/healthcheck/lastrun';

module.exports = function(robot) {

  robot.hear(/^(.*\.glgresearch\.com)\s+cerca\s+.*lastrun.*Down\s+ESCALATION/i, function(msg) {
    var _host = msg.match[2];

    if (!_host) {
      return;
    }

    doGetHealthcheckResponse(_host, function(err, response) {
      if (err) {
        msg.send("Error Getting Token:  " + err);
        return;
      }
      if (response) {
        msg.send("test");
        msg.send("/code " + JSON.stringify(response,null,2));
      }
    });
  });

  var doGetHealthcheckResponse = function doGetHealthcheckResponse(host, callback) {

    var url = cercaLastRunHealthcheckUrl;

    var options = {
      hostname: host,
      port: 443,
      path: url,
      method: 'GET'
    };

    var req = https.request(options, function(res) {
      var _buffer = "";
      res.setEncoding('utf8');
      res.on('data', function(chunk) {
        _buffer += chunk;
      });
      res.on('end', function() {
        var obj = {};
        try {
          obj = JSON.parse(_buffer);
        } catch (e) {
          callback("Could not parse JSON response");
        }
        callback(null, obj);
      });
    });

    req.on('error', function(e) {
      callback("Error with HTTP Post");
    });

    // write data to request body
    req.end();
  };

};
