// Description
//   Make an epildap link
//
// Commands:
//   ldap <search>

var epiLdapUrl = "https://jobs.glgresearch.com/epildap/searchldap?cn=";

module.exports = function(robot) {

  robot.hear(/(^ldap)\s+(.*)/i, function(msg) {
    var _search = msg.match[2];
    msg.send(epiLdapUrl + encodeURIComponent(_search) + "*");
  });

};
