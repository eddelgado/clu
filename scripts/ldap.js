// Description
//   Make an epildap link
//
// Commands:
//   ldap <search>
//   ldapuser <search>

function getURL(type) {
  var epiLdapUrl = "https://services.glgresearch.com/epildap/searchldap?" + type + "=";
  return epiLdapUrl;
}

module.exports = function(robot) {

  robot.hear(/(^ldap)\s+(.*)/i, function(msg) {
    var _search = msg.match[2];
    var url = getURL("cn");
    msg.send(url + encodeURIComponent(_search) + "*");
  });
  
  robot.hear(/(^ldapuser)\s+(.*)/i, function(msg) {
    var _search = msg.match[2];
    var url = getURL("sAMAccountName");
    msg.send(url + encodeURIComponent(_search) + "*");
  });
  
};
