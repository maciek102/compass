require 'rqrcode'

module Codes
  class QrCodeService
    def initialize(variant)
      @variant = variant
    end

    def call
      url = variant_url
      qr = RQRCode::QRCode.new(url, size: 10, level: :h)
      png = qr.as_png(
        color: 'black',
        background_color: 'white',
        border_modules: 4
      ).to_s
      attach_png(png)
    end

    private

    def variant_url
      Rails.application.routes.url_helpers.variant_url(@variant.id, host: ENV['APP_HOST'] || 'localhost:3000')
    end

    def attach_png(png)
      @variant.qr_code_image.attach(
        io: StringIO.new(png),
        filename: "qr_code_#{@variant.id}.png",
        content_type: 'image/png'
      )
    end
  end
end
