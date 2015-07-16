// Description
//   Verify Contact Info
//
// Commands:
//   verify contact info <personid> - Generate verify link for personid of a CM

var https = require('https');
var querystring = require('querystring');

module.exports = function(robot) {

  robot.hear(/^(verify contact info)\s+(\d+)$/i, function(msg) {
    var _personId = msg.match[2];

    if (!_personId) {
      return;
    }

    doGetToken(_personId, function(err, tokenResponse) {
      if (err) {
        msg.send("Error Getting Token:  " + err);
        return;
      }
      if (tokenResponse && tokenResponse.token) {
        msg.send("https://services.glgresearch.com/verify-contact-info/verify/" + tokenResponse.token);
      }
    });
  });

  var doGetToken = function doGetToken(personId, callback) {

    var postData = querystring.stringify({
      'personId': personId,
      'expiration_seconds': '100000000000'
    });

    var url = "";

    url += '/token';
    url += '/create';

    var options = {
      hostname: 'services.glgresearch.com',
      port: 443,
      path: url,
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Content-Length': postData.length
      }
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
    req.write(postData);
    req.end();
  };

};
