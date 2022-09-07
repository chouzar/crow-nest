import Mix.Config

# Configure the main viewport for the Scenic application
config :scen, :viewport, %{
  name: :main_viewport,
  size: {1280, 768},
  default_scene: Scen.Home,
  drivers: [
    [
      module: Scenic.Driver.Local,
      window: [title: "Local Window", resizeable: true],
      position: [scaled: true, centered: true, orientation: :normal]
    ]
  ]
}

config :scenic, :assets, module: Scen.Assets
