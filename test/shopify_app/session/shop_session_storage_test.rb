# frozen_string_literal: true
require 'test_helper'

class ShopMockSessionStore < ActiveRecord::Base
  include ShopifyApp::ShopSessionStorage

  def access_scopes=(shop, scopes)
    shop.access_scopes = scopes
  end

  def access_scopes(shop)
    shop.access_scopes
  end
end

module ShopifyApp
  class ShopSessionStorageTest < ActiveSupport::TestCase
    TEST_SHOPIFY_DOMAIN = "example.myshopify.com"
    TEST_SHOPIFY_TOKEN = "1234567890qwertyuiop"
    TEST_MERCHANT_SCOPES = 'read_products, write_orders'

    test ".retrieve can retrieve shop session records by ID" do
      ShopMockSessionStore.stubs(:find_by).returns(MockShopInstance.new(
        shopify_domain: TEST_SHOPIFY_DOMAIN,
        shopify_token: TEST_SHOPIFY_TOKEN,
        scopes: TEST_MERCHANT_SCOPES
      ))

      session = ShopMockSessionStore.retrieve(1)
      assert_equal TEST_SHOPIFY_DOMAIN, session.domain
      assert_equal TEST_SHOPIFY_TOKEN, session.token
      assert_equal TEST_MERCHANT_SCOPES, session.extra[:scopes]
    end

    test ".retrieve_by_shopify_domain can retrieve shop session records by JWT" do
      instance = MockShopInstance.new(
        shopify_domain: TEST_SHOPIFY_DOMAIN,
        shopify_token: TEST_SHOPIFY_TOKEN,
        api_version: '2020-01',
        scopes: TEST_MERCHANT_SCOPES
      )
      ShopMockSessionStore.stubs(:find_by).with(shopify_domain: TEST_SHOPIFY_DOMAIN).returns(instance)

      expected_session = ShopifyAPI::Session.new(
        domain: instance.shopify_domain,
        token: instance.shopify_token,
        api_version: instance.api_version,
        extra: { scopes: instance.access_scopes }
      )
      shopify_domain = TEST_SHOPIFY_DOMAIN

      session = ShopMockSessionStore.retrieve_by_shopify_domain(shopify_domain)
      assert_equal expected_session.domain, session.domain
      assert_equal expected_session.token, session.token
      assert_equal expected_session.api_version, session.api_version
      assert_equal expected_session.extra, session.extra
    end

    test ".store can store shop session records" do
      mock_shop_instance = MockShopInstance.new(id: 12345)
      mock_shop_instance.stubs(:save!).returns(true)

      ShopMockSessionStore.stubs(:find_or_initialize_by).returns(mock_shop_instance)

      mock_auth_hash = mock
      mock_auth_hash.stubs(:domain).returns(mock_shop_instance.shopify_domain)
      mock_auth_hash.stubs(:token).returns("a-new-token!")
      mock_auth_hash.stubs(:extra).returns({ scopes: TEST_MERCHANT_SCOPES })
      saved_id = ShopMockSessionStore.store(mock_auth_hash)

      assert_equal "a-new-token!", mock_shop_instance.shopify_token
      assert_equal mock_shop_instance.id, saved_id
    end

    test '.retrieve returns nil for non-existent shop' do
      shop_id = 'non-existent-id'
      ShopMockSessionStore.stubs(:find_by).with(id: shop_id).returns(nil)

      refute ShopMockSessionStore.retrieve(shop_id)
    end

    test '.retrieve_by_shopify_domain returns nil for non-existent shop' do
      shop_domain = 'non-existent-id'

      ShopMockSessionStore.stubs(:find_by).with(shopify_domain: shop_domain).returns(nil)

      refute ShopMockSessionStore.retrieve_by_shopify_domain(shop_domain)
    end

    test '.retrieve_access_scopes_by_shopify_domain returns access scopes for shop record' do
      instance = MockShopInstance.new(
        shopify_domain: TEST_SHOPIFY_DOMAIN,
        shopify_token: TEST_SHOPIFY_TOKEN,
        api_version: '2020-01',
        scopes: TEST_MERCHANT_SCOPES
      )
      ShopMockSessionStore.stubs(:find_by).with(shopify_domain: TEST_SHOPIFY_DOMAIN).returns(instance)

      actual_access_scopes = ShopMockSessionStore.retrieve_access_scopes_by_shopify_domain(TEST_SHOPIFY_DOMAIN)
      assert_equal TEST_MERCHANT_SCOPES, actual_access_scopes
    end

    test '.construct_session sets scopes to nil by handling NotImplementedError' do
      mock_shop = MockShopInstance.new(
        shopify_domain: TEST_SHOPIFY_DOMAIN,
        shopify_token: TEST_SHOPIFY_TOKEN
      )
      mock_shop.stubs(:access_scopes).raises(NoMethodError)
      ShopMockSessionStore.stubs(:find_by).returns(mock_shop)

      session = ShopMockSessionStore.retrieve(1)
      assert_equal TEST_SHOPIFY_DOMAIN, session.domain
      assert_equal TEST_SHOPIFY_TOKEN, session.token
      assert_nil session.extra[:scopes]
    end

    test '.construct_session sets scopes to nil by handling NoMethodError' do
      mock_shop = MockShopInstance.new(
        shopify_domain: TEST_SHOPIFY_DOMAIN,
        shopify_token: TEST_SHOPIFY_TOKEN
      )
      mock_shop.stubs(:access_scopes).raises(NotImplementedError)
      ShopMockSessionStore.stubs(:find_by).returns(mock_shop)

      session = ShopMockSessionStore.retrieve(1)
      assert_equal TEST_SHOPIFY_DOMAIN, session.domain
      assert_equal TEST_SHOPIFY_TOKEN, session.token
      assert_nil session.extra[:scopes]
    end
  end
end
