class User < ActiveRecord::Base
  has_and_belongs_to_many :services

  def self.create_user(name, password, email = '', phone = '', type = 'custom')
    new_user = User.new
    new_user.name = name
    new_user.salt = Time.now.hash.to_s[-6 .. -1]
    new_user.password = add_salt(password, new_user.salt)
    new_user.utype = type
    new_user.email = email
    new_user.phone = phone
    new_user.save if new_user.valid?
  end

  def authenticated?(input_password)
    self.password == add_salt(input_password, salt)
  end

  def has_access?(service)
    if self.services.exists?(service.id)
      true
    elsif self.utype == 'custom' && service.stype == 'custom'
      true
    else
      false
    end
  end

  private
  def add_salt(passwd, salt)
    Digest::MD5.hexdigest(passwd << salt)
  end
end
