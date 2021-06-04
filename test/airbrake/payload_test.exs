defmodule Airbrake.PayloadTest do
  use ExUnit.Case
  alias Airbrake.Payload

  def get_problem do
    try do
      # If the following line is not on line 9 then tests will start failing.
      # You've been warned!
      apply(Harbour, :cats, [3])
    rescue
      exception -> [exception, __STACKTRACE__]
    end
  end

  def get_payload(options \\ []) do
    apply(Payload, :new, List.insert_at(get_problem(), -1, options))
  end

  def get_error(options \\ []) do
    %{errors: [error]} = get_payload(options)
    error
  end

  def get_context(options \\ []) do
    %{context: context} = get_payload(options)
    context
  end

  describe "new/2 and new/3" do
    test "generates report with a REAL exception" do
      {exception, stacktrace} =
        try do
          apply(Harbour, :cats, [3])
        rescue
          exception -> {exception, __STACKTRACE__}
        end

      # This is probably VERY fragile, so if it sees a lot of churn, we can
      # break it down into smaller tests.
      assert %{
               apiKey: nil,
               context: %{environment: _, hostname: _},
               errors: [
                 %{
                   backtrace: [
                     %{file: "unknown", function: "Elixir.Harbour.cats(3)", line: 0},
                     %{
                       file: "test/airbrake/payload_test.exs",
                       function:
                         "Elixir.Airbrake.PayloadTest.test new/2 and new/3 generates report with a REAL exception/1",
                       line: _
                     },
                     %{file: "lib/ex_unit/runner.ex", function: "Elixir.ExUnit.Runner.exec_test/1", line: 391},
                     %{file: "timer.erl", function: "timer.tc/1", line: 166},
                     %{
                       file: "lib/ex_unit/runner.ex",
                       function: "Elixir.ExUnit.Runner.-spawn_test_monitor/4-fun-1-/4",
                       line: 342
                     }
                   ],
                   message: "function Harbour.cats/1 is undefined (module Harbour is not available)",
                   type: "UndefinedFunctionError"
                 }
               ],
               notifier: %{
                 name: "Airbrake Client",
                 url: "https://github.com/CityBaseInc/airbrake_client",
                 version: "0.9.0"
               }
             } = Payload.new(exception, stacktrace)
    end

    test "it reports the error class" do
      assert "UndefinedFunctionError" == get_error().type
    end

    test "it reports the error message" do
      assert "function Harbour.cats/1 is undefined (module Harbour is not available)" == get_error().message
    end

    test "it generates correct stacktraces" do
      {exception, stacktrace} =
        try do
          Enum.join(3, 'million')
        rescue
          exception -> {exception, __STACKTRACE__}
        end

      %{errors: [%{backtrace: stacktrace}]} = Payload.new(exception, stacktrace, [])

      assert [
               %{file: "lib/enum.ex", line: _, function: _},
               %{
                 file: "test/airbrake/payload_test.exs",
                 line: _,
                 function: "Elixir.Airbrake.PayloadTest.test new/2 and new/3 it generates correct stacktraces/1"
               }
               | _
             ] = stacktrace
    end

    test "it generates correct stacktraces when the current file was a script" do
      assert [
               %{file: "unknown", line: 0, function: _},
               %{
                 file: "test/airbrake/payload_test.exs",
                 line: 9,
                 function: "Elixir.Airbrake.PayloadTest.get_problem/0"
               },
               %{file: "test/airbrake/payload_test.exs", line: _, function: _} | _
             ] = get_error().backtrace
    end

    # NOTE: Regression test
    test "it generates correct stacktraces when the method arguments are in place of arity" do
      {exception, stacktrace} =
        try do
          apply(Foo, :bar, [:qux, 1, "foo\n"])
        rescue
          exception -> {exception, __STACKTRACE__}
        end

      %{errors: [%{backtrace: stacktrace}]} = Payload.new(exception, stacktrace, [])

      assert [
               %{file: "unknown", line: 0, function: "Elixir.Foo.bar(:qux, 1, \"foo\\n\")"},
               %{file: "test/airbrake/payload_test.exs", line: _, function: _} | _
             ] = stacktrace
    end

    test "it reports the notifier" do
      assert %{name: "Airbrake Client", url: "https://github.com/CityBaseInc/airbrake_client", version: _} =
               get_payload().notifier
    end

    test "it adds the context when given" do
      %{context: context} = get_payload(context: %{msg: "Potato#cake"})
      assert "Potato#cake" == context.msg
    end

    test "it filters sensitive params" do
      Application.put_env(:airbrake_client, :filter_parameters, ["password"])
      payload = get_payload(params: %{"password" => "top_secret", "x" => "y"})
      assert "[FILTERED]" == payload.params["password"]
      assert "y" == payload.params["x"]
      Application.delete_env(:airbrake_client, :filter_parameters)
    end
  end
end
