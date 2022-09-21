defmodule CrowNest.Assets do
  use Scenic.Assets.Static,
    otp_app: :crow_nest,
    sources: [
      "assets",
      {:scenic, "deps/scenic/assets"}
    ],
    alias: [
      spritesheet_piece_black: "images/pixel-chess-pieces-black-16x16-32x48.png",
      spritesheet_piece_white: "images/pixel-chess-pieces-white-16x16-32x48.png"
    ]
end
