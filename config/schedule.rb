# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
set :output, "/home/jsomers/www/readertron/log/cron.log"
#
every 5.hours do
  runner "Feed.refresh"
end

every 1.day do
  runner "Report.daily"
  runner "Report.append_to_historical_data"
end

every :sunday, :at => '3pm' do
  runner "User.send_weekly_digests"
end

every 1.month do
  runner "Post.delete_old_posts"
end

# Learn more: http://github.com/javan/whenever