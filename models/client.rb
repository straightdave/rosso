class Client < ActiveRecord::Base

  def build_mac(content)
    Digest::MD5.hexdigest("#{content}_#{self.skey}")
  end

end
