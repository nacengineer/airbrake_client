use Mix.Config

config :airbrake_client,
  private: [http_adapter: Airbrake.HTTPMock]
