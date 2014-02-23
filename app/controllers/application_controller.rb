class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :use_mobile_templates
  
  def use_mobile_templates
    if browser.mobile?
      prepend_view_path 'app/views/mobile'
    end
  end
end