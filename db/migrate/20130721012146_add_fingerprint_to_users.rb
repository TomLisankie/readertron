class AddFingerprintToUsers < ActiveRecord::Migration
  def change
    add_column :users, :fingerprint, :string
    
    fingerprints = {
      "jsomers@gmail.com" => "James",
      "nsrivast@gmail.com" => "Nikhil",
      "avinashvora@gmail.com" => "Avi",
      "jcobb@jd12.law.harvard.edu" => "John",
      "shafman4@gmail.com" => "Chip",
      "robert.trangucci@gmail.com" => "Rob",
      "mikesilber@gmail.com" => "Silber",
      "drew.blacker@gmail.com" => "Drew",
      "laura.fong@gmail.com" => "Laura",
      "eric.potash@gmail.com" => "Eric",
      "jyl702@gmail.com" => "Jimmy",
      "tvchurch@gmail.com" => "Tom",
      "sharon.traiberman@gmail.com" => "Sharon",
      "rzipken@gmail.com" => "Romy",
      "justinsbecker@gmail.com" => "Justin",
      "pingoaf@gmail.com" => "Freedman",
      "ssharma6@gmail.com" => "Sonam",
      "s.menke@gmail.com" => "Menke",
      "adamjuliangoldstein@gmail.com" => "Goldstein",
      "gmaylward@gmail.com" => "Michael"
    }
    
    fingerprints.each do |e, f|
      User.find_by_email(e).update_attribute(:fingerprint, f)
    end
  end
end