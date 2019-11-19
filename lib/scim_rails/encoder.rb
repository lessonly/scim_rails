require "jwt"

module ScimRails
  module Encoder
    extend self

    def encode(company)
      payload = {
        iat: Time.current.to_i,
        ScimRails.config.basic_auth_model_searchable_attribute =>
          company.public_send(ScimRails.config.basic_auth_model_searchable_attribute)
      }

      JWT.encode(payload, ScimRails.config.signing_secret, ScimRails.config.signing_algorithm)
    end

    def decode(token)
      verify = ScimRails.config.signing_algorithm != ScimRails::Config::ALGO_NONE

      JWT.decode(token, ScimRails.config.signing_secret, verify, algorithm: ScimRails.config.signing_algorithm).first
    rescue JWT::VerificationError, JWT::DecodeError
      raise ScimRails::ExceptionHandler::InvalidCredentials
    end
  end
end
