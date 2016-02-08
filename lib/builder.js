var jenkins_url = process.env.JENKINS_URL ||
    'http://jenkins.rhub.me';
var jenkins = require('jenkins');
var jenkins_xml = require('../lib/jenkins_xml');

function builder(job, callback) {

    var conn = jenkins(jenkins_url);
    add_pkg(conn, job, function(err) {
	if (err) { callback(err); return; }
	callback(null);
    })
}

function add_pkg(conn, job, callback) {

    add_jenkins_job(conn, job, function(err) {
	if (err) { console.log(err); callback(err); return; }

	build_jenkins_job(conn, job, function(err) {
	    if (err) { console.log(err); callback(err); return; }
	    callback(null);
	})
    })
}

function add_jenkins_job(conn, job, callback) {
    var job_name = jenkins_job_name(job);
    jenkins_xml(job, function(err, job_xml) {
	if (err) { callback(err); return; }
	conn.job.create(
	    job_name,
	    job_xml,
	    function(err) {
		if (err) { console.log(err); callback(err); return; }
		callback(null);
	    }
	)
    })
}

function build_jenkins_job(conn, job, callback) {
    var job_name = jenkins_job_name(job);
    conn.job.build(
	job_name,
	{ 'parameters': {
	    'package': job.package,
	    'filename': job.filename,
	    'url': job.url }
	},
	function(err) {
	    if (err) { console.log(err); callback(err); return; }
	    callback(null)
	}
    )
}

function jenkins_job_name(job) {
    return job.package + '-' + job.filename;
}

module.exports = builder;
