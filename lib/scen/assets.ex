defmodule Scen.Assets do
  use Scenic.Assets.Static,
    otp_app: :scen,
    sources: [
      "assets",
      {:scenic, "deps/scenic/assets"}
    ],
    alias: [
      froggy: "images/froggy.PNG"
    ]
end
