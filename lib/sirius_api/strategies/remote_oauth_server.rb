require 'faraday'
require 'faraday_middleware'
require 'ostruct'
require 'warden'

module SiriusApi
  module Strategies
    ##
    # Simple Warden strategy that authorizes requests with a Bearer access
    # token using a remote OAuth 2.0 authorization server.
    #
    # Note: It's implemented for proprietary Zuul OAAS Provider API that is
    # already deprecated. It should be modified after deploying a newer version
    # of Zuul OAAS on CTU.
    #
    # TODO: Implement caching and write tests!
    #
    class RemoteOAuthServer < Warden::Strategies::Base

      AUTHORIZATION_HEADERS = Rack::Auth::AbstractRequest::AUTHORIZATION_KEYS
      CHECK_TOKEN_URI = Config.oauth_check_token_uri
      REQUIRED_SCOPE = 'urn:ctu:oauth:sirius.read'

      def store?
        false
      end

      def authenticate!
        if access_token.blank?
          fail 'Missing access token.'
          return
        end

        token = request_token_info(access_token)

        if error_msg = validate_token_info(token)
          fail error_msg
        else
          success! token.user_id.freeze
        end
      end

      def access_token
        authz_header = env.select { |key| AUTHORIZATION_HEADERS.include? key }
           .values.select { |v| v.start_with? 'Bearer ' }
           .map { |v| v.split(' ', 2).last }
           .first

        authz_header || params['access_token']
      end

      def request_token_info(token_value)
        resp = http_client.get(CHECK_TOKEN_URI, token: token_value)
        OpenStruct.new(resp.body).tap do |s|
          s.status = resp.status
        end
      end

      def validate_token_info(token)
        return "Invalid access token." if token.status == 404
        return "Unable to verify access token (#{token.status})." if token.status != 200
        return "Invalid response from the authorization server." if token.client_id.blank?
        return "Insufficient scope: #{token.scope.join(' ')}." unless token.scope.include? REQUIRED_SCOPE
        return "Token is not authorized by any user." if token.user_id.blank?
        return nil
      end

      def http_client
        Faraday.new do |c|
          c.response :json, content_type: /\bjson$/
          c.adapter Faraday.default_adapter
        end
      end
    end
  end
end

Warden::Strategies.add(:remote_oauth_server, SiriusApi::Strategies::RemoteOAuthServer)