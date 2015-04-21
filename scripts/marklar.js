// Description
//   Make an epildap link
//
// Commands:
//   ldap <search>

var consultationUrl = "services.glgresearch.com/marklar/api/call/details?top=50&consultationId=";

module.exports = function(robot) {

  robot.hear(/.*consultations\/#\/consultation\/(\d+)$/, function(msg) {
    var _consultationId = msg.match[1];
    msg.send(consultationUrl + encodeURIComponent(_consultationId));
  });

};
