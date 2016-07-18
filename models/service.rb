class Service < ActiveRecord::Base
  has_and_belongs_to_many :users

  def self.create_service(name, type)
    new_svc = Service.new
    new_svc.name = name
    new_svc.type = case type
    when 'mng'    then 'mng'
    when 'inner'  then 'inner'
    when 'vendor' then 'vendor'
    else 'custom'
    end

    new_svc.appkey = SecureRandom.base64
    new_svc.skey   = SecureRandom.hex
    new_svc.save if new_svc.valid?
  end

  def refresh_keys!
    self.appkey = SecureRandom.base64
    self.skey   = SecureRandom.hex
    self.save if self.valid?
  end

  def build_mac(content)
    Digest::MD5.hexdigest("#{content}_#{self.skey}")
  end
end
