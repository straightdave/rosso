class User < ActiveRecord::Base
  has_and_belongs_to_many :services

  def authenticated?(input_password)
    self.password == add_salt(input_password, salt)
  end

  def has_access?(service)
    self.services.exists?(service.id)
  end

  private
  def add_salt(passwd, salt)
    Digest::MD5.hexdigest(passwd << salt)
  end
end
