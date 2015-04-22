// Description
//   Redisplay a link to the marklar details of the same consultation
//
// Commands:
//   <consultation link>

var consultationUrl = "services.glgresearch.com/marklar/api/call/details?consultationId=";

module.exports = function(robot) {

  robot.hear(/.*consultations\/#\/consultation\/(\d+)$/, function(msg) {
    var _consultationId = msg.match[1];
    msg.send(consultationUrl + encodeURIComponent(_consultationId));
  });

};
