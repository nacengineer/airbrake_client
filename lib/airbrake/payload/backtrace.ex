defmodule Airbrake.Payload.Backtrace do
  @moduledoc false

  def from_stacktrace(stacktrace) do
    Enum.map(stacktrace, fn
      {module, function, args, []} ->
        %{
          file: "unknown",
          line: 0,
          function: "#{module}.#{function}#{format_args(args)}"
        }

      {module, function, args, [file: file, line: line_number]} ->
        %{
          file: file |> List.to_string(),
          line: line_number,
          function: "#{module}.#{function}#{format_args(args)}"
        }

      string ->
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
    end)
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
