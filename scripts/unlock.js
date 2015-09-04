// Description
//   Unlock a user account
//
// Commands:
//   unlock <username>

// Orders controllable logging
var log = require('iphb-logs');
// Ldap foo
var ldap = require('../lib/ldap.js');
// Event Emitters
var events = require('events');
var emitter = new events.EventEmitter();
// List of domain controllers
var domainControllers = process.env.DOMAIN_CONTROLLERS;

// Respect orders settings for logging
log.enable.logging = process.env.ENABLE_LOGGING ? true : false;
log.enable.debug = process.env.ENABLE_DEBUG ? true : false;
log.enable.verbose = process.env.ENABLE_VERBOSE ? true : false;

// ***********************************************************************
// Guards
// ***********************************************************************
if (!domainControllers) {
  var _msg = [
    "Must Set Environment Vars:",
    "   DOMAIN_CONTROLLERS"
  ].join('\n');
  log.error(_msg);
  process.exit(1);
}
// Split the domain controllers into an array
domainControllers = domainControllers.split(' ');

// ***********************************************************************
// Main
// ***********************************************************************

// Listen for ldapComplete events and check
// the status buffer to see if they are all complete
// before we send our response back to the user
//
// You might be asking why we used an event?  Me too
//
// We need to call out to several LDAP servers to 'unlock' a users
// account.  This allows for the action to be instant.  Those calls
// can happen randomly.  We do not want to respond until they are all
// complete.  SO, we track all of them in the statusBuffer and call
// an event each time something completes.  Below we check each time
// an event occurs to see if everything is done before we proceed
emitter.on("ldapComplete", function(msg, username, statusBuffer) {

  // If we aren't finished unlocking and checking if their password has expired
  // we are not ready to proceed yet
  if (statusBuffer.ldapUnlockCounter !== 0 || statusBuffer.ldapSearchComplete !== true) {
    log.verbose("ldapComplete Event but Not Done:", statusBuffer.ldapUnlockCounter, statusBuffer.ldapSearchComplete);
    return;
  }

  // Create an output Text Buffer
  var _outputText = "";

  // Wrap the output in a properly formatted twilio response
  // Check if we had errors unlocking
  if (statusBuffer.err) {
    // TODO: What do we do if it didn't work?
    _outputText += "Account Unlock Failed [" + username + "].  ";
  } else {
    _outputText += "Account Unlock Successful - [" + username + "].  ";
  }

  // Check if their password has expired - if yes, let them know
  if (statusBuffer.passwordReset === true) {
    _outputText += "The password has expired and must be reset to login.";
  }
  // Send the final output buffer
  log.info("Successfully Unlocked Account [", username, "]");
  return msg.send(_outputText);
});


var unlockUser = function(msg, unlockUsername) {
  // An object where we store various statuses as we hit LDAP endpoints
  var _statusBuffer = {};
  // Semaphore for our ldap unlock calls
  _statusBuffer.ldapUnlockCounter = 0;
  // Set a flag as false until search is complete
  _statusBuffer.ldapSearchComplete = false;

  /**
   * @abstract The following checks whether the users password is also expired.
   *           If the users password is expired we will notify them they need
   *           to change it.  (Which they can do in Okta)
   */
  // Filter for the LDAP search for the user
  var _filter = "";
  if (~unlockUsername.indexOf("@")) {
    _filter = '(&(mail=' + unlockUsername + '))';
  } else {
    _filter = '(&(sAMAccountName=' + unlockUsername + '))';
  }
  // Return all attributes for the user
  var _attr = [
    'pwdLastSet',
    'lockoutTime'
  ];
  // Perform an ldap Search
  ldap.ldapSearch(_filter, _attr, function(result) {
    if (!result[0]) {
      return msg.send(["User [", unlockUsername, "] Not Found"].join(''));
    }
    // Convert Windows Epoch to Linux Epoch
    // 1.1.1600 -> 1.1.1970 difference in seconds = 11644473600
    log.verbose("  unlockUsername pwdLastSet:", result[0].pwdLastSet);
    var passwordLastResetToEpoch = (result[0].pwdLastSet / 10000) - 11644473600000;
    // var passwordLastResetToEpoch = (result[0].pwdLastSet / 100000) - 11644473600;
    // Now get 'now' as epoch for linux
    var date = new Date();
    var epoch = date.getTime();
    // If the time now is >= when the password needed to be reset
    // the users password is expired
    var _daysToExpire = 60;
    // Add the amount of time we allow a password to live to the time in
    // active directory.  Above we had to conver the windows timestamp
    // to unix timestame.  Now we're adding $days * $hrs * $min * $sec * $ms
    var _calculatedResetEpoch = passwordLastResetToEpoch + _daysToExpire * 24 * 60 * 60 * 1000;
    log.verbose("  unlockUsername epoch:", epoch);
    log.verbose("  unlockUsername passwordLastResetToEpoch:", passwordLastResetToEpoch);
    log.verbose("  unlockUsername calculatedResetEpoch:", _calculatedResetEpoch);
    if (epoch >= _calculatedResetEpoch) {
      // Password Expired
      _statusBuffer.passwordReset = true;
    }
    // Flag that our search finished
    _statusBuffer.ldapSearchComplete = true;
    log.verbose("R:",result);
      // Don't proceed if the user isn't locked out
    if (result[0].lockoutTime === "0") {
      var _msg = ["User [", unlockUsername, "] Not Locked Out"].join('');
      if (_statusBuffer.passwordReset) {
        _msg += "  Their password has expired.";
      }
      return msg.send(_msg);
    }

    // Emit the event that we are done
    emitter.emit("ldapComplete", msg, unlockUsername, _statusBuffer);

    // Foreach Domain Controller
    var c = domainControllers.length;
    while (c--) {
      // Yoink the ip for read'ability
      var _ip = domainControllers[c];
      // These async calls need to all complete
      // before we send our final respone so we
      // keep track of how many are still running
      // and when they are all done .. the event
      // listener will finally trigger the response
      // to the user
      _statusBuffer.ldapUnlockCounter++;
      // Go unlock the users account
      ldap.unlockUserAccount(_ip, unlockUsername, function(err, address, username) {
        // If there was an error with this region
        if (err) {
          // Log to console
          log.warn("Error Unlocking Account [", username, "] on [", address, "]:", err);
          // Initialize the error object
          if (!_statusBuffer.err) {
            _statusBuffer.err = {};
          }
          // Set the error for this region
          _statusBuffer.err[_ip] = err;
        }
        // Finally we are done so forget about this reset
        _statusBuffer.ldapUnlockCounter--;
        // ... and Emit the event that we've completed
        emitter.emit("ldapComplete", msg, username, _statusBuffer);
      });
    }
  });
};

module.exports = function(robot) {
  robot.hear(/^unlock\s+(.*)\s*/i, function(msg) {
    var _username = msg.match[1];
    log.warn("Unlock Request For [", _username, "] From:", msg.message.user);
    unlockUser(msg, _username);
  });
};

// ***********************************************************************
// Tests
// ***********************************************************************

if (module.parent === null) {
  // Enable Logging
  log.enable.logging = process.env.ENABLE_LOGGING ? true : false;
  log.enable.debug = process.env.ENABLE_DEBUG ? true : false;
  log.enable.verbose = process.env.ENABLE_VERBOSE ? true : false;
  log.enable.tests = true;

  var _msg = {
    send: function(msg) {
      log.warn("Results:", msg);
    }
  };

  var _user = "spatel";

  unlockUser(_msg, _user);
}
