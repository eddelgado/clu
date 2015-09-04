// Description
//   Starphleet Support
//
// Commands:
//   starphleet <service> watch - Proactively watch status changes for a service in a region
//   starphleet <service> status - Get the status of a service for each region
//   starphleet <service> redeploy - HARD redeploy a service for each region
//   starphleet quiet - Stop listening to services you've watched
//   status - Get the status of clu for each region

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

  var _friendlyRegions = {
    "starphleet[us-east-1c]": "starphleet[east]",
    "starphleet[us-west-2c]": "starphleet[west]",
    "starphleet[eu-west-1c]": "starphleet[europe]",
    "starphleet[ap-northeast-1a]": "starphleet[asia]",
    "jobs[us-west-2c]": "jobs[west]"
  };

  // Support the die command
  robot.respond(/DIE$/i, function(msg) {
    process.exit(0);
  });

  robot.hear(/^status$/i, function(msg) {
    doSendResponse(msg, robot.name + " is online");
  });

  robot.hear(/^(starphleet|s)\s+(\w+|\d+)$/i, function(msg) {
    var _command = msg.match[2];
    switch (_command) {
      case "quiet":
        doHandleQuietCommand(msg);
        break;
      default:
        doSendResponse(msg, _command + " is not recognized");
        break;
    }
  });

  robot.hear(/^sc\s+(.*)$/i, function(msg) {

    var _command = msg.match[1];

    exec(_command, function(err, stdout, stderr) {
      if (err) {
        throw err;
      }

      msg.send("/code \n" + stdout);
    });
  });

  robot.hear(/^(starphleet|s)\s+(\w+|\d+)\s+(\w+|\d+)$/i, function(msg) {
    var _service = msg.match[2];
    var _command = msg.match[3];
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
        doSendResponse(msg, _command + " is not recognized");
        break;
    }
  });

  var doSendResponse = function doSendResponse(msg, response) {
    // Try to build a response that specifies our region
    var _response = "";
    if (_friendlyRegions[process.env.LABEL]) {
      _response += _friendlyRegions[process.env.LABEL] + ": ";
    } else {
      _response += process.env.LABEL ? process.env.LABEL + ": " : "";
    }
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
      // If the git repo exists we'll redeploy
      fs.lstat(_path, function(err, stats) {
        if (err || !stats.isDirectory()) {
          doSendResponse(msg, service + " not found");
          return;
        }
        doRunRootHostCommand("starphleet-redeploy " + service);
        _reply = "Redeployed [" + service + "]: started";
        doSendResponse(msg, _reply);
        doHandleWatchUntilOnlineCommand(msg, service);
      });
    } catch (Exception) {
      doSendResponse(msg, service + " not found");
    }
  };

  var doRunRootHostCommand = function doRunRootHostCommand(cmd) {
    var _commandDir = "/var/starphleet/headquarters/clucommands";
    var _commandFile = _commandDir + "/orders";
    var _cmds = [];
    fs.lstat(_commandFile, function(err, stats) {
      if (err || !stats.isFile()) {
        _cmds.push("sudo mkdir -p " + _commandDir);
        _cmds.push('echo "sudo rm ' + _commandFile + '" | sudo tee -a "' + _commandFile + '"');
      }
      _cmds.push('echo "' + cmd + '" | sudo tee -a "' + _commandFile + '"');
      for (var c = 0; c < _cmds.length; c++) {
        // console.log(_cmds[c]);
        // console.dir(exec);
        // console.dir(_cmds);
        exec(_cmds[c], function(err, stdout, stderr) {
          if (err) {
            throw err;
          }
        });
      }
    });
  };

  var doGetStatusFromCurrentOrders = function doGetStatusFromCurrentOrders(service, cb) {
    // Build a bath to the status file
    var _path = "";
    _path += process.env.PATH_STARPHLEET_CURRENT_ORDERS;
    _path += "/" + service;
    _path += "/" + process.env.FILE_STARPHLEET_ORDERS_STATUS;
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

  var doHandleQuietCommand = function doHandleQuietCommand(msg) {
    var _name = msg.message.user.name;
    doClearIntervalTimer(_name);
    doSendResponse(msg, "Watch disabled [" + _name + "]");
  };

  var doHandleWatchUntilOnlineCommand = function doHandleWatchUntilOnlineCommand(msg, service) {
    var _name = msg.message.user.name;
    var _previousStatus = "";
    var _isReadyToComplete = false;
    var _reply = "";
    doClearIntervalTimer(_name);
    _watchers[_name] = setInterval(function doWatchFileAndReportDiffs() {
      doGetStatusFromCurrentOrders(service, function(currentStatus) {
        if (currentStatus !== "online" && _isReadyToComplete) {
          _isReadyToComplete = true;
        }
        if (_previousStatus !== currentStatus) {
          _reply = "Service [" + service + "]: " + currentStatus;
          doSendResponse(msg, _reply);
          _previousStatus = currentStatus;
        }
        if (currentStatus === "online" && _isReadyToComplete) {
          _reply = "Service [" + service + "]: complete";
          doSendResponse(msg, _reply);
          doClearIntervalTimer(_name);
        }
      });
    }, 1000);
  };

  var doHandleWatchCommand = function doHandleWatchCommand(msg, service) {
    var _name = msg.message.user.name;
    var _previousStatus = "";
    doClearIntervalTimer(_name);
    _watchers[_name] = setInterval(function doWatchFileAndReportDiffs() {
      doGetStatusFromCurrentOrders(service, function(currentStatus) {
        if (_previousStatus !== currentStatus) {
          var _reply = "Watching [" + service + "]: " + currentStatus;
          doSendResponse(msg, _reply);
          _previousStatus = currentStatus;
        }
      });
    }, 1000);
  };

  var doHandleStatusCommand = function doHandleStatusCommand(msg, service) {
    try {
      doGetStatusFromCurrentOrders(service, function(data) {
        var _reply = "Service [" + service + "]: " + data;
        doSendResponse(msg, _reply);
      });
    } catch (Exception) {
      console.dir(Exception);
      doSendResponse(msg, service + " not found");
    }
  };
};
