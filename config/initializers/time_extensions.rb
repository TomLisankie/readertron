Time.class_eval do
  def in_eastern_time
    in_time_zone('Eastern Time (US & Canada)')
  end
end

ActiveSupport::TimeWithZone.class_eval do
  def in_eastern_time
    in_time_zone('Eastern Time (US & Canada)')
  end
end