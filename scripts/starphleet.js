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
var fs = require('fs');
var exec = require('child_process').exec;

// If no HEADQUARTERS path is set.. punt
if (!process.env.PATH_STARPHLEET_HEADQUARTERS) {
  robot.logger.warning("Missing Environment Variable: PATH_STARPHLEET_HEADQUARTERS");
  return;
}
// We need the 'file' associated with orders statuses
if (!process.env.FILE_STARPHLEET_ORDERS_STATUS) {
  robot.logger.warning("Missing Environment Variable: FILE_STARPHLEET_ORDERS_STATUS");
  return;
}
// We need the 'path' for current_orders
if (!process.env.PATH_STARPHLEET_CURRENT_ORDERS) {
  robot.logger.warning("Missing Environment Variable: PATH_STARPHLEET_CURRENT_ORDERS");
  return;
}

module.exports = function(robot) {

  var _watchers = {};

  robot.hear(/^starphleet\s*(\w+|\d+)\s*(\w+|\d+).*/i, function(msg) {
    var _command = msg.match[1];
    var _service = msg.match[2];
    switch (_command) {
      case "status":
        doHandleStatusCommand(msg, _service);
        break;
      case "redeploy":
        doHandleRedeployCommand(msg, _service);
        break;
      case "watch":
        doHandleWatchCommand(msg, _service);
        break;
      case "quiet":
        doHandleQuietCommand(msg, _service);
        break;
      default:
        break;
    }
  });

  var doSendResponse = function doSendResponse(msg, response) {
    // Try to build a response that specifies our region
    var _response = "";
    _response += process.env.LABEL ? process.env.LABEL + ": " : "";
    _response += response;
    // Send the response back to the requestor
    msg.send(_response);
  };

  var doClearIntervalTimer = function doClearIntervalTimer(user) {
    if (_watchers[user]) {
      clearInterval(_watchers[user]);
    }
  };


  var doHandleRedeployCommand = function doHandleRedeployCommand(msg, service) {
    try {
      // Build a path to the git repo
      var _path = "";
      _path += process.env.PATH_STARPHLEET_HEADQUARTERS;
      _path += "/" + service;
      _path += "/git";
      // Open the file and return to the user
      fs.lstat(_path, function(err, stats) {
        if (!stats.isDirectory() || err) {
          doSendResponse(msg, service + " not found");
        }
        exec('sudo rm -rf ' + _path);
        doSendResponse(msg, service + " redeploying");
      });
    } catch (Exception) {
      doSendResponse(msg, service + " not found");
    }
  };

  var doGetStatusFromCurrentOrders = function doGetStatusFromCurrentOrders(service, cb) {
    // Build a bath to the status file
    var _path = "";
    _path += process.env.PATH_STARPHLEET_CURRENT_ORDERS;
    _path += "/" + service;
    _path += "/" + process.env.FILE_STARPHLEET_ORDERS_STATUS;
    console.log("P: " + _path);
    // The status files in starphleet contain a small blurb about
    // the deployment status of this service.  Just return it to the user
    fs.readFile(_path, 'utf8', function(err, data) {
      // Throw an exception if we have a problem
      if (err) {
        throw "File Error";
      }
      // Otherwise call back with the data
      cb(data);
    });
  }

  var doHandleQuietCommand = function doHandleQuietCommand(msg, service) {
    var _name = msg.message.user.name;
    doClearIntervalTimer(_name);
  };

  var doHandleWatchCommand = function doHandleWatchCommand(msg, service) {
    var _name = msg.message.user.name;
    var _previousStatus = "";
    doClearIntervalTimer(_name);
    _watchers[_name] = setInterval(function doWatchFileAndReportDiffs() {
      doGetStatusFromCurrentOrders(service, function(currentStatus) {
        console.log("PS", _previousStatus);
        console.log("CS", currentStatus);
        if (_previousStatus !== currentStatus) {
          var _reply = "Service [" + service + "]: " + currentStatus;
          doSendResponse(msg, _reply);
          _previousStatus = currentStatus;
        }
      });
    }, 1000);
  };

  var doHandleStatusCommand = function doHandleStatusCommand(msg, service) {
    try {
      doGetStatusFromCurrentOrders(service, function(data) {
        doSendResponse(msg, data);
      });
    } catch (Exception) {
      console.dir(Exception);
      doSendResponse(msg, service + " not found");
    }
  };
};
