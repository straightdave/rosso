class User < ActiveRecord::Base
  has_and_belongs_to_many :clients, class_name: "Client"

  def authenticated?(input_password)
    self.password == add_salt(input_password, salt)
  end

  private
  def add_salt(passwd, salt)
    Digest::MD5.hexdigest(passwd << salt)
  end
end
