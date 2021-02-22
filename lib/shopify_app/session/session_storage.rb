# frozen_string_literal: true
module ShopifyApp
  module SessionStorage
    extend ActiveSupport::Concern

    included do
      validates :shopify_token, presence: true
      validates :api_version, presence: true
    end

    def with_shopify_session(&block)
      ShopifyAPI::Session.temp(
        domain: shopify_domain,
        token: shopify_token,
        api_version: api_version,
        &block
      )
    end

    def access_scopes=(scopes)
      super(scopes)
    rescue NotImplementedError, NoMethodError
      Rails.logger.warn("#access_scopes= must be defined to handle storing access scopes: #{scopes}")
    end

    def access_scopes
      super
    rescue NotImplementedError, NoMethodError => exception
      raise exception.class, "#access_scopes= must be defined to hook into stored access scopes"
    end
  end
end
