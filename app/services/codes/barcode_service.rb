require 'barby'
require 'barby/barcode/ean_13'
require 'barby/outputter/png_outputter'

module Codes
  class BarcodeService
    def initialize(variant)
      @variant = variant
    end

    def call
      ensure_ean_present
      barcode = Barby::EAN13.new(@variant.ean)
      png = Barby::PngOutputter.new(barcode).to_png(height: 150, margin: 10)
      attach_png(png)
    end

    private

    def ensure_ean_present
      return if @variant.ean.present?

      loop do
        base_number = format('%012d', @variant.id + rand(1_000_000))
        begin
          barcode = Barby::EAN13.new(base_number)
          unless Variant.exists?(ean: barcode.data)
            @variant.update!(ean: barcode.data)
            break
          end
        rescue StandardError
          next
        end
      end
    end

    def attach_png(png)
      @variant.barcode_image.attach(
        io: StringIO.new(png),
        filename: "barcode_#{@variant.id}.png",
        content_type: 'image/png'
      )
    end
  end
end
