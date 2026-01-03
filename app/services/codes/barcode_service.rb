require 'barby'
require 'barby/barcode/ean_13'
require 'barby/outputter/png_outputter'
require 'mini_magick'
require 'stringio'
require 'tempfile'

module Codes
  class BarcodeService
    BARCODE_WIDTH  = 2
    BARCODE_HEIGHT = 100
    MARGIN         = 20

    def initialize(variant)
      @variant = variant
    end

    def call
      ensure_ean_present

      barcode = Barby::EAN13.new(@variant.ean)
      png = Barby::PngOutputter.new(barcode).to_png(
        xdim: BARCODE_WIDTH,
        height: BARCODE_HEIGHT,
        margin: MARGIN
      )

      final_png = add_text_under_barcode(png, @variant.ean)
      attach_png(final_png)
    end

    private

    def add_text_under_barcode(png_data, text)
      Tempfile.create(['barcode', '.png']) do |file|
        file.binmode
        file.write(png_data)
        file.rewind

        image = MiniMagick::Image.open(file.path)

        image.combine_options do |c|
          c.gravity 'south'
          c.background 'white'
          c.splice '0x25'
          c.font 'Arial'
          c.pointsize '16'
          c.fill 'black'
          c.annotate '+0+5', formatted_ean(text)
        end

        image.to_blob
      end
    end

    def formatted_ean(ean)
      "#{ean[0]} #{ean[1..4]} #{ean[5..9]} #{ean[10..12]}"
    end

    def ensure_ean_present
      return if @variant.ean.present?

      loop do
        base_number = format('%012d', @variant.id + rand(1_000_000))
        barcode = Barby::EAN13.new(base_number)

        unless Variant.exists?(ean: barcode.data)
          @variant.update!(ean: barcode.data)
          break
        end
      rescue StandardError
        next
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
