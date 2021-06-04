defmodule Airbrake.Payload do
  @moduledoc false

  @notifier_info %{
    name: "Airbrake Client",
    version: Airbrake.Mixfile.project()[:version],
    url: Airbrake.Mixfile.project()[:package][:links][:github]
  }

  defstruct apiKey: nil,
            context: nil,
            environment: nil,
            errors: nil,
            notifier: @notifier_info,
            params: nil,
            session: nil

  alias Airbrake.Payload.Backtrace

  def new(exception, stacktrace, options \\ [])

  def new(%{__exception__: true} = exception, stacktrace, options) do
    new(Airbrake.Worker.exception_info(exception), stacktrace, options)
  end

  def new(exception, stacktrace, options) when is_list(exception) do
    %__MODULE__{}
    |> add_error(
      exception,
      stacktrace,
      Keyword.get(options, :context),
      Keyword.get(options, :env),
      Keyword.get(options, :params),
      Keyword.get(options, :session)
    )
  end

  defp add_error(payload, exception, stacktrace, context, env, params, session) do
    payload
    |> add_exception_info(exception, stacktrace)
    |> add_context(context)
    |> add_env(env)
    |> add_params(params)
    |> add_session(session)
  end

  defp add_exception_info(payload, exception, stacktrace) do
    error = %{
      type: exception[:type],
      message: exception[:message],
      backtrace: Backtrace.from_stacktrace(stacktrace)
    }

    Map.put(payload, :errors, [error])
  end

  defp env do
    case Application.get_env(:airbrake_client, :environment) do
      nil -> hostname()
      {:system, var} -> System.get_env(var) || hostname()
      atom_env when is_atom(atom_env) -> to_string(atom_env)
      str_env when is_binary(str_env) -> str_env
      fun_env when is_function(fun_env) -> fun_env.()
    end
  end

  def hostname do
    System.get_env("HOST") || to_string(elem(:inet.gethostname(), 1))
  end

  defp add_context(payload, context) do
    context = Map.merge(%{environment: env(), hostname: hostname()}, context || %{})
    Map.put(payload, :context, context)
  end

  defp add_env(payload, nil), do: payload
  defp add_env(payload, env), do: Map.put(payload, :environment, env)

  defp add_params(payload, nil), do: payload
  defp add_params(payload, params), do: Map.put(payload, :params, filter_parameters(params))

  defp add_session(payload, nil), do: payload
  defp add_session(payload, session), do: Map.put(payload, :session, session)

  defp filter_parameters(params) do
    case Airbrake.Worker.get_env(:filter_parameters) do
      nil ->
        params

      filter_params ->
        Enum.into(params, %{}, fn {k, v} ->
          if Enum.member?(filter_params, k), do: {k, "[FILTERED]"}, else: {k, v}
        end)
    end
  end
end
