// Description
//   Make an epildap link
//
// Commands:
//   ldap <search>

var consultationUrl = "services.glgresearch.com/marklar/api/call/details?consultationId=";

module.exports = function(robot) {

  robot.hear(/.*consultations\/#\/consultation\/(\d+)$/, function(msg) {
    var _consultationId = msg.match[1];
    msg.send(consultationUrl + encodeURIComponent(_consultationId) + encodeURIComponent('&top=50'));
  });

};