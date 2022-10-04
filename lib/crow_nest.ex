defmodule CrowNest do
  @moduledoc false

  alias CrowNest.Session

  def start(_type, _args) do
    # load the viewport configuration from config
    main_viewport_config = Application.get_env(:crow_nest, :viewport)

    # start the application with the viewport
    children = [
      {Scenic,
       [
         main_viewport_config
       ]},
      {DynamicSupervisor, strategy: :one_for_one, name: SessionSupervisor},
      CrowNest.SubjectStore,
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end

end
