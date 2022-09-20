import Mix.Config

# Configure the main viewport for the Scenic application
config :crows, :viewport, %{
  name: :main_viewport,
  size: {600, 650},
  default_scene: Crows.Scene.Home,
  drivers: [
    [
      module: Scenic.Driver.Local,
      window: [title: "Local Window", resizeable: true],
      position: [scaled: true, centered: true, orientation: :normal]
    ]
  ]
}

config :scenic, :assets, module: Crows.Assets
