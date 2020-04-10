require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'
  gem 'jwt'
end
SECRET="7efa0ff3eae67b21ac8fdb0b127e1748de087acd81086b38145e904cc7717f2bee86f1755305eaef0a2b6d095686e40b13ebe437c001b28a2a86ed20f510b433"
NONCE="abcdef"
COMPANY_ID=123
USER_ID=456
SUBDOMAIN='ujet.co'
COMPANY=OpenStruct.new({id: COMPANY_ID, subdomain: SUBDOMAIN})
USER=OpenStruct.new(id: USER_ID, nonce: NONCE, company_id: COMPANY.id)
TIME_NOW=1586389735
TIME_WEEK_FROM_NOW=1586994535

class AuthToken

  class UnauthorizedException < Exception; end

  def self.issue_token(payload)
    payload[:iss] = "UJET"
    payload[:iat] = TIME_NOW

    JWT.encode(payload, SECRET)
  end

  def self.decode(token)
    raise ServiceException, "Token is blank" if token.nil? || token == ""
    JWT.decode(token, SECRET)
  end

  def self.authenticate(token)
    convert_exceptions do
      payload, header = decode(token)
      puts "payload: #{payload.inspect}"
      puts "header: #{header.inspect}"
      result = OpenStruct.new
      result.type = payload["type"]
      result.company = get_company(payload)
      case payload["type"]
      when "user"
        result.user = get_user(payload, token)
      when "end_user"
        # token issued for the end_user. (used for the mobile request)
        result.user = EndUser.find(payload["end_user_id"])
        result.device = Device.find(payload["device_id"])
      else
        raise UnauthorizedException, "Invalid auth token type"
      end

      result
    end
  end

  def self.need_refresh(token)
    payload, header = decode(token)
    payload["exp"] && Time.at(payload["exp"]) < 1.day.since
  end

  def self.user_token(user)
    company = fetch_company(user.company_id)
    issue_token(
      user_id: user.id,
      company_id: user.company_id,
      subdomain: company.subdomain,
      nonce: user.nonce,
      type: "user",
      exp: TIME_WEEK_FROM_NOW)
  end

  private

  def self.convert_exceptions
    yield
    rescue JWT::ExpiredSignature
      raise UnauthorizedException, "Auth token is expired"
    rescue JWT::DecodeError
      raise UnauthorizedException, "Invalid auth token"
    # rescue ActiveRecord::RecordNotFound => error
    #   raise UnauthorizedException, "Invalid auth token : #{error.message}"
  end

  def self.get_company(payload)
    company = fetch_company(payload["company_id"])
    # validate company_id of the token matches with the current company
    if payload["company_id"] != company.id
      raise UnauthorizedException, "Invalid auth token company id #{payload["company_id"].inspect}"
    end

    # validate subdomain of the token matches with the current company
    if payload["subdomain"] and payload["subdomain"] != company.subdomain
      raise UnauthorizedException, "Invalid auth token subdomain #{payload["subdomain"].inspect}"
    end
    company
  end

  def self.get_user(payload, token)
    user = fetch_user(payload["user_id"])
    if user.nil?
      raise UnauthorizedException, "Invalid auth token: User not found"
    end

    if payload["nonce"] != user.nonce
      message = "auth_token_nonce #{payload["nonce"]} is invalid, token = #{token}"
      puts( "#{message}, agent_id: #{user.id}")
      raise UnauthorizedException, "Auth token is revoked"
    end
    user
  end

  def self.fetch_company(id)
    return nil if id != COMPANY.id
    COMPANY
  end

  def self.fetch_user(id)
    return nil if USER.id != id
    USER
  end
end

if ARGV.empty?
  token = AuthToken.user_token(USER)
  puts token
  puts AuthToken.authenticate(token).inspect
else
  ARGV.each do |token|
    puts token
    puts AuthToken.authenticate(token).inspect
  end
end
# use cases:
# `issue_token`
# { agent_id: current_user.id } dynamics_controller, zendesk_controller
# { user_id: self.id } user
# { user_id: exp: now + 7.day} invites_controller
# { end_user_id: end_user_id } device
