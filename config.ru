# This file is used by Rack-based servers to start the application.

require ::File.expand_path('../config/environment',  __FILE__)

if Rails.env.production?
  DelayedJobWeb.use Rack::Auth::Basic do |username, password|
    username == 'admin' && password == Report.find_by_report_type("Backdoor").content
  end
end

run Readertron::Application
