ActiveRecord::Base.class_eval do
  class << self
    def method_missing(m, *args, &block)
      if m.match(/(.*?)_like/)
        self.where("#{$1} like '%#{args.first}%'")
      else
        super
      end
    end
  end
end