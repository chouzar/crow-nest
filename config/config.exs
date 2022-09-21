import Mix.Config

# Configure the main viewport for the Scenic application
config :crow_nest, :viewport, %{
  name: :main_viewport,
  size: {600, 650},
  default_scene: CrowNest.Scene.Home,
  drivers: [
    [
      module: Scenic.Driver.Local,
      window: [title: "Local Window", resizeable: true],
      position: [scaled: true, centered: true, orientation: :normal]
    ]
  ]
}

config :scenic, :assets, module: CrowNest.Assets
