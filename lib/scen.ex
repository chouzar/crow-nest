defmodule Scen do
  @moduledoc false

  def start(_type, _args) do
    # load the viewport configuration from config
    main_viewport_config = Application.get_env(:scen, :viewport)

    # start the application with the viewport
    children = [
      {Scenic,
       [
         main_viewport_config
       ]}
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
