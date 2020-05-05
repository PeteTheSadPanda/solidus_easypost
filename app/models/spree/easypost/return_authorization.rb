require 'forwardable'

module Spree
  module EasyPost
    class ReturnAuthorization
      extend Forwardable

      attr_reader :return_authorization

      def_delegators :@return_authorization, :stock_location, :order, :inventory_units

      def initialize(return_authorization)
        @return_authorization = return_authorization
      end

      def easypost_shipment
        @ep_shipment ||= ::EasyPost::Shipment.create(
          {
            from_address: stock_location.easypost_address(easypost_api_key),
            to_address: order.ship_address.easypost_address(easypost_api_key),
            parcel: build_parcel,
            is_return: true
          },
          easypost_api_key
        )
      end

      def return_label(rate)
        easypost_shipment.buy(rate) unless easypost_shipment.postage_label
        easypost_shipment.postage_label
      end

      private

      def easypost_api_key
        order&.account&.easypost_api_key
      end

      def build_parcel
        total_weight = inventory_units.joins(:variant).sum(:weight)

        ::EasyPost::Parcel.create({ weight: total_weight }, easypost_api_key)
      end
    end
  end
end
