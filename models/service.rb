class Service < ActiveRecord::Base
  has_and_belongs_to_many :users

  def build_mac(content)
    Digest::MD5.hexdigest("#{content}_#{self.skey}")
  end
end
