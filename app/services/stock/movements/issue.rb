module Stock
  module Movements
    # Serwis intencyjny do wydania towaru z magazynu
    class Issue
      class Error < StandardError; end

      def self.call(stock_operation:, quantity:, item_ids: [], user: nil, note: nil, **args)
        new(stock_operation: stock_operation, quantity: quantity, item_ids: item_ids, user: user, note: note).call
      end

      def initialize(stock_operation:, quantity:, item_ids: [], user: nil, note: nil)
        @stock_operation = stock_operation # operacja magazynowa
        @variant = stock_operation.variant # wariant do wydania
        @quantity = quantity.to_i # ilość do wydania
        @item_ids = item_ids # wybrane itemy do wydania (opcjonalne)
        @user = user
        @note = note
      end

      def call
        validate!

        @items = Item.where(id: item_ids)

        validate_items!

        ActiveRecord::Base.transaction do
          # 1. Rozliczenie rezerwacji
          reconcile_reservations!

          # 2. Tworzymy stock movement
          movement = Stock::Movements::Move.call(
            stock_operation: stock_operation,
            quantity: quantity,
            direction: :out,
            movement_type: "sale",
            user: user,
            note: note
          )

          # 3. Oznaczamy itemy jako wydane
          issue_items(movement)
        end
      end
      

      private

      attr_reader :stock_operation, :variant, :quantity, :item_ids, :user, :note, :items

      def validate!
        raise Error, "Quantity must be positive" if quantity <= 0
        raise Error, "Variant disabled" if variant.disabled?
      end

      def validate_items!
        raise Error, "Not enough items selected" if items.size < quantity
        raise Error, "Too many items selected" if items.size > quantity

        unless items.all? { |i| i.variant_id == variant.id }
          raise Error, "Selected items do not match variant"
        end
      end

      # wydanie itemów i powiązanie ich z ruchem magazynowym
      def issue_items(movement)
        issued_count = 0
        items.each do |item|
          break if issued_count >= quantity

          # zawsze przy wydaniu usuwamy rezerwację
          item.update!(status: :issued, reserved_stock_operation: nil)
          movement.items << item
          issued_count += 1
        end
      end

      # rozliczenie rezerwacji na podstawie wybranych itemów
      # jeżeli wybrano inne itemy niż zarezerwowane, zwolnij zbędne rezerwacje
      def reconcile_reservations!
        remaining_after_issue = stock_operation.remaining_quantity - quantity

        # Obecnie zarezerwowane itemy
        reserved_items = Item.where(
          organization_id: stock_operation.organization_id,
          variant_id: variant.id,
          reserved_stock_operation_id: stock_operation.id,
          status: Item.statuses[:reserved]
        )

        selected_ids_set = items.pluck(:id).to_set

        # itemy zarezerwowane NIE wybrane do wydania
        unselected_reserved = reserved_items.where.not(id: selected_ids_set)

        # liczby do zwolnienia
        will_remain_reserved = unselected_reserved.count
        should_remain_reserved = remaining_after_issue
        to_release_count = will_remain_reserved - should_remain_reserved

        # zwalniamy tylko nadmiar rezerwacji, LIFO (ostatnie najpierw)
        if to_release_count > 0
          items_to_release = unselected_reserved.order(received_at: :desc, id: :desc).limit(to_release_count)
          items_to_release.find_each(&:unreserve!)
        end
      end

    end
  end
end
