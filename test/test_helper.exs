ExUnit.start()
Application.ensure_all_started(:mox)
# this seems to be necessary for Elixir 1.10
Application.ensure_all_started(:stream_data)
