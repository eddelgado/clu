// Ldap library for talking to AD
var ldap = require('ldapjs');
// Order controllable logs
var log = require('iphb-logs');

// ***********************************************************************
// Environment
// ***********************************************************************
// The Service credentials for TextToUnlock - the Full DN
var ldapUser = process.env.LDAP_USER;
var ldapPassword = process.env.LDAP_PASS;
// Can't use DNS names in starphleet for internal servers
// also notice we are using LDAP_S_ - so port 636
var ldapServer = process.env.LDAP_SERVER;
// The Base DN for all searches
var ldapBase = process.env.LDAP_BASE;

// ***********************************************************************
// Guards
// ***********************************************************************
if (!ldapUser || !ldapPassword || !ldapServer || !ldapBase) {
  var _msg = [
    "Must Set Environment Vars:",
    "   LDAP_USER",
    "   LDAP_PASS",
    "   LDAP_SERVER",
    "   LDAP_BASE"
  ].join('\n');
  log.error(_msg);
  process.exit(1);
}

var api = {
  // ldapUnlockUserAccount
  //    - Accepts ip_address/hostname of ldap server
  //    -         username to unlock
  //    -         callback
  //
  //    - Example:
  //              _ipaddress = "127.0.0.1"
  //              _username = "jdoe"
  //
  //              ldapUnlockUserAccount(_ipaddress,_username, function (err) {
  //                if (err) { return; } // shucks
  //                // Success
  //              });
  unlockUserAccount: function(address, username, callback) {
    // First we search for the user's details we want to unlock
    // -
    // Filter for the LDAP search for the user
    var _filter = "";
    if (~username.indexOf("@")) {
      _filter = '(&(mail=' + username + '))';
    } else {
      _filter = '(&(sAMAccountName=' + username + '))';
    }
    // Return all attributes for the user
    var _attr = [];
    // Now search for the user
    api.ldapSearch(_filter, _attr, function(result) {
      // Now contact the LDAP server sent to us (address)
      // and unlock the users account on that server
      // -
      // Create a connection to the LDAP server
      log.verbose("LDAP unlockUserAccount [", username, "] on DC [", address, "]");
      var client = ldap.createClient({
        url: "ldap://" + address
      });
      // Authenticate to the ldap server
      client.bind(ldapUser, ldapPassword, function(err) {
        if (err) {
          var _msg = ["Auth Error: [", address, "]", err].join(' ');
          log.debug(_msg);
          // Return since we had a problem
          return callback(_msg, address, username);
        }
        // This is the attribute uses to unlock an account
        // and the object required for nodes ldapjs
        var _changeObject = {
          operation: 'replace',
          modification: {
            lockoutTime: "0"
          }
        };
        // Create the ldapjs node object for the change
        var _change = new ldap.Change(_changeObject);
        // Modify the user's DN with the _change and report any errors [err]
        client.modify(result[0].dn, _change, function(err) {
          // Disconnect from the LDAP server
          client.unbind();
          // Call back with any status
          callback(err, address, username);
        });
        // Done
      });
    });
  },

  // encodeMicrosoftPassword
  //    - Accepts
  //    -     password (string)
  //    - Returns
  //    -     UTF-16LE encoded password string
  //    - Example:
  //              _encodedPassword = encodeMicrosoftPassword("plainPassword");
  //
  encodeMicrosoftPassword: function(password) {
    return new Buffer('"' + password + '"', 'utf16le').toString();
    // return new Buffer('"' + password + '"', 'utf16le').toString();
  },

  // ldapSearch
  //    - Accepts ldapFilter
  //    -         ldapAttributes
  //    -         callback
  //
  //    - Example:
  //              _ldapFilter = "(&(mail=*))";
  //              _ldapAttributes = ["sAMAccountName","mail"];
  //
  //              ldapSearch(_ldapFilter,_ldapAttributes, function (results) {
  //                console.dir(results)
  //              });
  ldapSearch: function(ldapFilter, ldapAttributes, callback) {

    // Create a connection to the LDAP server
    log.verbose("LDAP Connect ldapSearch [", ldapServer, "]");
    var client = ldap.createClient({
      url: ldapServer
    });
    // Authenticate to the ldap server
    client.bind(ldapUser, ldapPassword, function(err) {
      if (err) {
        // Return since we had a problem
        // TODO: Maybe should be verbal about a failure
        log.error("Authenication Failed in ldapSearch: " + err);
        return;
      }
    });

    // Build our options for the ldap search
    var opts = {
      filter: ldapFilter,
      attributes: ldapAttributes,
      scope: 'sub'
    };

    // Perform he LDAP search
    log.verbose("ldapSearch:", ldapBase, opts);
    client.search(ldapBase, opts, function(searchErr, searchResponse) {
      // ASYNC responses so we are going to buffer them before we
      // call the original caller
      var _resultsBuffer = [];
      // If there's an error we can just punt
      if (searchErr) {
        log.error("Search Had an Error: " + searchErr);
        // Return since we had a problem
        return;
      }
      // When a search result is found we get a searchEntry event
      searchResponse.on('searchEntry', function(entry) {
        // Buffer responses until done
        _resultsBuffer.push(entry.object);
      });
      // Capture errors
      searchResponse.on('error', function(err) {
        // TODO: Do something betterer with errors
        log.error('error: ' + err.message);
      });
      // When we get an event 'end' the query has completed
      searchResponse.on('end', function(result) {
        // If the status was zero we can disconnect from the LDAP server
        if (result.status === 0) {
          // Disconnect from the server
          client.unbind();
        }
        // If no results were found send something friendly
        // letting the caller know
        if (_resultsBuffer.length === 0) {
          return callback({
            "Results": "No Matches for Search"
          });
        }
        // Send back the resultbuffer
        callback(_resultsBuffer);
      });
    });
  }
};

module.exports = api;

/********************************************************************
 * Tests - Only executed for testing
 ********************************************************************/
if (module.parent === null) {
  // Enable Logging
  log.enable.logging = process.env.ENABLE_LOGGING ? true : false;
  log.enable.debug = process.env.ENABLE_DEBUG ? true : false;
  log.enable.verbose = process.env.ENABLE_VERBOSE ? true : false;
  log.enable.tests = true;

  // Capture any failed tests
  var _module = "ldap.js";
  var _test = "";

  var _address = "10.114.1.221";
  var _un = "bhudgens";

  _test = "unlockUserAccount";
  api.unlockUserAccount(_address, _un, function(err) {
    if (err) {
      return log.fail(_module, _test, "failed");
    }

    return log.success(_module, _test, "success");
  });
}
