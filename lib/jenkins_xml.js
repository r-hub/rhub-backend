var fs = require('fs');
var mustache = require('mustache');
var xml_encode = require('../lib/xml_encode');

function jenkins_xml(job, callback) {

    // For the transition, we don't have ostype
    var os = job.ostype || 'Linux';
    os = os.toLowerCase();
    var template = './templates/job-' + os + '.xml';

    fs.readFile(
	template,
	'utf8',
	function(err, template) {
	    if (err) { console.log(err); callback(err); return; }

	    fs.readFile(
		'./templates/commands-' + os + '.txt',
		'utf8',
		function(err, command) {
		    if (err) { console.log(err); callback(err); return; }
		    var labels = job.platforminfo['node-labels'] || [];
		    labels.push('swarm');
		    labels = labels.join(' && ');
		    var data = { 'commands': xml_encode(command),
				 'email': xml_encode(job.email),
				 'labels': xml_encode(labels)  };
		    var res = mustache.render(template, data);
		    callback(null, res);
		}
	    )
	}
    )
}

module.exports = jenkins_xml;
