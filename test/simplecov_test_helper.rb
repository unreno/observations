#	separated out this so could modify without 
#	always restarting all the tests.
#
#	This isn't even coming close to 100%
#	It is showing most things as untested which is confusing.
#
require 'simplecov'
SimpleCov.start 'rails' do
#	add_filter 'lib/method_missing_with_authorization.rb'
#	add_filter 'lib/ucb_ldap-1.4.2'
	add_filter 'app/channels/application_cable/channel.rb' #	what is this?
	add_filter 'app/channels/application_cable/connection.rb' #	what is this?
	add_filter 'app/jobs/application_job.rb' #	what is this?
	add_filter 'app/mailers/application_mailer.rb' #	what is this?
	merge_timeout 72000
end
#
#	I would really like to figure out how to include the views!
#	Apparently, can't (don't like that word) because the coverage
#	monitor is triggered by the "require" call.  Perhaps I can
#	figure out how to "require" all of the views?
#
