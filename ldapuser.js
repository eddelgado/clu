// Description
//   Make an epildap link
//
// Commands:
//   ldap <search>

var epiLdapUrl = "https://services.glgresearch.com/epildap/searchldap?sAMAccountName=";

module.exports = function(robot) {

  robot.hear(/(^ldapuser)\s+(.*)/i, function(msg) {
    var _search = msg.match[2];
    msg.send(epiLdapUrl + encodeURIComponent(_search) + "*");
  });

};
