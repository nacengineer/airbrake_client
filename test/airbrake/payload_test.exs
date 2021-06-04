defmodule Airbrake.PayloadTest do
  use ExUnit.Case
  alias Airbrake.Payload

  @exception %UndefinedFunctionError{
    arity: 1,
    function: :cats,
    message: nil,
    module: Harbour,
    reason: nil
  }

  @stacktrace [
    {Harbour, :cats, [3], []},
    {:erl_eval, :do_apply, 6, [file: 'erl_eval.erl', line: 680]},
    {:erl_eval, :try_clauses, 8, [file: 'erl_eval.erl', line: 914]},
    {:elixir, :recur_eval, 3, [file: 'src/elixir.erl', line: 280]},
    {:elixir, :eval_forms, 3, [file: 'src/elixir.erl', line: 265]},
    {IEx.Evaluator, :handle_eval, 5, [file: 'lib/iex/evaluator.ex', line: 261]},
    {IEx.Evaluator, :do_eval, 3, [file: 'lib/iex/evaluator.ex', line: 242]},
    {IEx.Evaluator, :eval, 3, [file: 'lib/iex/evaluator.ex', line: 220]}
  ]

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

    test "reports the error class of an exception" do
      assert %{errors: [error]} = Payload.new(@exception, @stacktrace)
      assert "UndefinedFunctionError" == error.type
    end

    test "reports the type when explicitly specified"

    test "reports the error message from an exception" do
      assert %{errors: [error]} = Payload.new(@exception, @stacktrace)

      assert "function Harbour.cats/1 is undefined (module Harbour is not available)" ==
               error.message
    end

    test "reports the error message when explicitly specified"

    # TODO: extract Airbrake.Payload.Backtrace to test stacktrace-to-backtrace separately
    # TODO: stacktrace tests here can be done with dependency injection to replace all of the stacktrace tests with just one

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
      assert %Payload{errors: [error]} = Payload.new(@exception, @stacktrace)

      # This is TEMPORARY.  The stacktrace to backtrace translation needs better tests.
      assert [
               %{file: "unknown", function: "Elixir.Harbour.cats(3)", line: 0},
               %{file: "erl_eval.erl", function: "erl_eval.do_apply/6", line: 680},
               %{file: "erl_eval.erl", function: "erl_eval.try_clauses/8", line: 914},
               %{file: "src/elixir.erl", function: "elixir.recur_eval/3", line: 280},
               %{file: "src/elixir.erl", function: "elixir.eval_forms/3", line: 265},
               %{file: "lib/iex/evaluator.ex", function: "Elixir.IEx.Evaluator.handle_eval/5", line: 261},
               %{file: "lib/iex/evaluator.ex", function: "Elixir.IEx.Evaluator.do_eval/3", line: 242},
               %{file: "lib/iex/evaluator.ex", function: "Elixir.IEx.Evaluator.eval/3", line: 220}
             ] = error.backtrace
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

    test "reports the notifier" do
      assert %{name: "Airbrake Client", url: "https://github.com/CityBaseInc/airbrake_client", version: _} =
               Payload.new(@exception, @stacktrace).notifier
    end

    test "sets a default context"

    test "sets the context when given" do
      %{context: context} = Payload.new(@exception, @stacktrace, context: %{msg: "Potato#cake"})
      assert "Potato#cake" == context.msg
    end

    test "sets environment (and rename) when given"

    test "sets params when given"

    test "sets session when given"

    test "it filters sensitive params" do
      Application.put_env(:airbrake_client, :filter_parameters, ["password"])
      payload = Payload.new(@exception, @stacktrace, params: %{"password" => "top_secret", "x" => "y"})
      assert "[FILTERED]" == payload.params["password"]
      assert "y" == payload.params["x"]
      Application.delete_env(:airbrake_client, :filter_parameters)
    end
  end

  describe "Poison encoding" do
    test "with minimal options"
    test "with all options"
  end

  describe "Jason encoding" do
    test "with minimal options"
    test "with all options"
  end
end
