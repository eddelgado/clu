// Description
//   Make an epildap link
//
// Commands:
//   ldap <search>
//   ldapuser <search>

var epiLdapUrl = "";

function getURL(type) {
  epiLdapUrl = "https://services.glgresearch.com/epildap/searchldap?" + type + "=";
  return epiLdapUrl;
}

module.exports = function(robot) {

  robot.hear(/(^ldap)\s+(.*)/i, function(msg) {
    var _search = msg.match[2];
    getURL("cn");
    msg.send(epiLdapUrl + encodeURIComponent(_search) + "*");
  });
  
  robot.hear(/(^ldapuser)\s+(.*)/i, function(msg) {
    var _search = msg.match[2];
    getURL("sAMAccountName");
    msg.send(epiLdapUrl + encodeURIComponent(_search) + "*");
  });
  
};
