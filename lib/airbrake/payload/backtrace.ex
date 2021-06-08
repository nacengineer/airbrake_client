defmodule Airbrake.Payload.Backtrace do
  @moduledoc false

  def from_stacktrace(stacktrace),
    do: Enum.map(stacktrace, &from_stacktrace_entry/1)

  def from_stacktrace_entry({module, function, args, []}) do
    %{
      file: "unknown",
      line: 0,
      function: "#{format_module(module)}.#{function}#{format_args(args)}"
    }
  end

  def from_stacktrace_entry({module, function, args, [file: file, line: line_number]}) do
    %{
      file: file |> List.to_string(),
      line: line_number,
      function: "#{format_module(module)}.#{function}#{format_args(args)}"
    }
  end

  def from_stacktrace_entry(string) when is_binary(string) do
    info = Regex.named_captures(~r/(?<app>\(.*?\))\s*(?<file>.*?):(?<line>\d+):\s*(?<function>.*)\z/, string)

    if info do
      %{
        file: info["file"],
        line: String.to_integer(info["line"]),
        function: "#{info["app"]} #{info["function"]}"
      }
    else
      %{
        file: "unknown",
        line: 0,
        function: string
      }
    end
  end

  def format_module(module) do
    string = Atom.to_string(module)
    if String.starts_with?(string, "Elixir."), do: string, else: ":#{string}"
  end

  defp format_args(args) when is_integer(args) do
    "/#{args}"
  end

  defp format_args(args) when is_list(args) do
    "(#{
      args
      |> Enum.map(&inspect(&1))
      |> Enum.join(", ")
    })"
  end
end
