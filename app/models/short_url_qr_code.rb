# frozen_string_literal: true

# Renders the QR code PNG for a short URL. Shared by the web UI and the API.
module ShortUrlQrCode
  PNG_OPTIONS = {
    bit_depth: 1,
    border_modules: 1,
    color_mode: ChunkyPNG::COLOR_GRAYSCALE,
    color: "black",
    file: nil,
    fill: "white",
    module_px_size: 6,
    resize_exactly_to: false,
    resize_gte_to: false,
    size: 400
  }.freeze

  def self.png(short_url)
    RQRCode::QRCode.new(short_url).as_png(PNG_OPTIONS)
  end

  def self.filename(url)
    "brkmn-qr-#{url.shortened}.png"
  end
end
