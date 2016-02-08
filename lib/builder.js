var jenkins_url = process.env.JENKINS_URL ||
    'http://jenkins.rhub.me';
var jenkins = require('jenkins');

function builder(job, callback) {

    var conn = jenkins(jenkins_url);
    conn.info(function(err, cb) {
	if (err) { callback(err); return; }
	callback(null);
    })
}

module.exports = builder;
