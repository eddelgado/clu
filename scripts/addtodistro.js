var log = require('iphb-logs');
var ldap = require('../lib/ldap.js');
var events = require('events');
var emitter = new events.EventEmitter();
var domainControllers = process.env.DOMAIN_CONTROLLERS;

log.enable.logging = process.env.ENABLE_LOGGING ? true : false;
log.enable.debug = process.env.ENABLE_DEBUG ? true : false;
log.enable.verbose = process.env.ENABLE_VERBOSE ? true : false;

if (!domainControllers) {
  var _msg = [
    "Must Set Environment Vars:",
    " DOMAIN_CONTROLLERS"
  ].join('\n');
  log.error(_msg);
  process.exit(1);
}

domainControllers = domainControllers.split(' ');

emitter.on("ldapComplete", function(username, distroGroup, statusBuffer) {
  if (statusBuffer.ldapCheckMembers !== 0 || statusBuffer.ldapSearchComplete !== true) {
    log.verbose("ldapComplete Event but Not Done:", statusbuffer.ldapCheckMembers, statusBuffer.ldapSearchComplete);
    return;
  }

  var _outputText = "";

  if (statusBuffer.err) {
    _outputText += "User Add to Distro Failed [" + username + "]" + "[" + distroGroup + "]";
  } else {
    _outputText += "User Add to Distro Successful [" + username + "]" + "[" + distroGroup + "]";
  }
  // TODO: Is statusBuffer needed? 

});

var addUsertoDistro = function(msg, username, distroGroup) {
  // add the user to the group
  var _filter = '(&(sAMAccountName=' + distro + '))';
  var _attr = [
    'sAMAccountType',
    'member'
  ];
  ldap.ldapSearch(_filter, _attr, function(result) {
    if (!result[0]) {
      return msg.send(["Distro Group [", distroGroup, "] Not Found"].join(''));
    }
    var _ip = domainControllers[0];
    ldap.addUsertoDistroGroup(_ip, username, distroGroup, function(err, address, user, distro) {
      if (err) {
        log.warn("Error Adding User to Distro [", username,"], [", distroGroup, "] on [", address, "]:", err);
      }
      emitter.emit("ldapComplete", msg, user, distro);
    });
  });
};


module.exports = function(robot) {
  robot.respond(/add\s+(.+)\s+to\s+(.+)\s*/i, function(msg) {
    var _username = msg.match[1];
    var _distro = msg.match[2];
    log.warn("Add User to Distro Request: [", + _username + "] ", + "[", + _distro +"]");
    addUsertoDistro(msg, _username, _distro);
  });
};
