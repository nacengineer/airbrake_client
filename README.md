# Airbrake Client

Capture exceptions and send them to the [Airbrake](http://airbrake.io) or to
your [Errbit](http://errbit.com/) installation.

This library was originally forked from the
[`airbrake`](https://hex.pm/packages/airbrake) Hex package.  Development and
support for that library seems to have lapsed, but we (the devs at
[CityBase](https://thecitybase.com/)) had changes and updates we wanted to make.
So we decided to publish our own fork of the library.

## Installation

Add `airbrake_client` to your dependencies:

```elixir
defp deps do
  [
    {:airbrake_client, "~> 0.8"}
  ]
end
```

If you are switching from the original `airbrake` library, you should only have
to switch the dependency to `:airbrake_client`.  Version 0.8.0 of this library
(its first) should be a drop-in replacement.

## Configuration

Configure `:airbrake`:

```elixir
config :airbrake,
  api_key: System.get_env("AIRBRAKE_API_KEY"),
  project_id: System.get_env("AIRBRAKE_PROJECT_ID"),
  environment: Mix.env(),
  filter_parameters: ["password"],
  host: "https://api.airbrake.io" # or your Errbit host

config :logger,
  backends: [{Airbrake.LoggerBackend, :error}, :console]
```

Required configuration arguments:

  * `:api_key` - (binary) the token needed to access the [Airbrake
    API](https://airbrake.io/docs/api/). You could find it in [User
    Settings](https://airbrake.io/users/edit).
  * `:project_id` - (integer) the id of your project at Airbrake.

Options configuration arguments:

  * `:environment` - (binary or function returning binary) the environment that
    will be attached to each reported exception.
  * `:filter_parameters` - (list of binaries) allows to filter out sensitive
    parameters such as passwords and tokens.
  * `:host` - (binary) use it when you have an Errbit installation.
  * `:ignore` - (MapSet of binary or function returning boolean or :all) allows
    to ignore some or all exceptions.  See examples below.
  * `:options` - (keyword list or function returning keyword list) values that
    are included in all reports to Airbrake.io.  See examples below.

### Ignoring some exceptions

To ignore some exceptions use the `:ignore` config key.  The value can be a
`MapSet`:

```elixir
config :airbrake,
  ignore: MapSet.new(["Custom.Error"])
```

The value can also be a two-argument function:

```elixir
config :airbrake,
  ignore: fn type, message ->
    type == "Custom.Error" && String.contains?(message, "silent error")
  end
```

Or the value can be the atom `:all` to ignore all errors (and effectively
turning off all reporting):

```elixir
config :airbrake,
  ignore: :all
```

### Shared options for reporting data to Airbrake

If you have data that should _always_ be reported, they can be included in the
config with the `:options` key.  Its value should be a keyword list with any of
these keys: `:context`, `:params`, `:session`, and `:env`.

```elixir
config :airbrake,
  options: [env: %{"SOME_ENVIRONMENT_VARIABLE" => "environment variable"}]
```

Alternatively, you can specify a function (as a tuple) which returns a keyword
list (with the same keys):

```elixir
config :airbrake,
  options: {Web, :airbrake_options, 1}
```

The function takes a keyword list as its only parameter; the function arity is
always 1.

## Usage

### Phoenix app

```elixir
defmodule YourApp.Router do
  use Phoenix.Router
  use Airbrake.Plug # <- put this line to your router.ex

  # ...
end
```

```elixir
  def channel do
    quote do
      use Phoenix.Channel
      use Airbrake.Channel # <- put this line to your web.ex
      # ...
```

### Report an exception

```elixir
try do
  String.upcase(nil)
rescue
  exception -> Airbrake.report(exception)
end
```

### GenServer

Use `Airbrake.GenServer` instead of `GenServer`:

```elixir
defmodule MyServer do
  use Airbrake.GenServer
  # ...
end
```

### Any Elixir process

By pid:

```elixir
Airbrake.monitor(pid)
```

By name:

```elixir
Airbrake.monitor(Registered.Process.Name)
```
