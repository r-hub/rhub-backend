var debug = require('debug');
var builder = require('./lib/builder');
var amqp = require('amqplib');

var broker_url = process.env.RABBITMQ_URL ||
    'amqp://q.rhub.me:5672/rhub';

function run(q) {

    amqp.connect(broker_url).then(function(conn) {
	process.once('SIGINT', function() { conn.close(); });
	return conn.createChannel().then(function(ch) {
	    var ok = ch.assertQueue(q, {durable: true});
	    ok = ok.then(function() { ch.prefetch(1); });
	    ok = ok.then(function() {
		ch.consume(q, doWork, {noAck: false});
	    });
	    return ok;

	    function doWork(msg) {
		var msg_obj = JSON.parse(msg.content.toString());
		console.log("STARTED: " + msg_obj);

		builder(msg_obj, function(error) {
		    if (!error) {
			console.log("DONE: " + msg_obj.package);
			ch.ack(msg);
		    } else {
			console.log("ERROR: " + msg_obj.package);
		    }
		})
	    }
	})
    }).then(null, console.warn);
}

module.exports = run;
