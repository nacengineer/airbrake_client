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
    {:timer, :tc, 1, [file: 'timer.erl', line: 166]}
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
      assert %Payload{
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
                     %{file: "timer.erl", function: ":timer.tc/1", line: 166},
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
      assert %Payload{errors: [error]} = Payload.new(@exception, @stacktrace)
      assert "UndefinedFunctionError" == error.type
    end

    test "reports the type when explicitly specified" do
      exception_keyword_list = [
        type: "SomeAwfulError",
        message: "something really bad happened"
      ]

      assert %Payload{errors: [%{type: "SomeAwfulError"}]} = Payload.new(exception_keyword_list, @stacktrace)
    end

    test "reports the error message from an exception" do
      assert %Payload{errors: [error]} = Payload.new(@exception, @stacktrace)

      assert "function Harbour.cats/1 is undefined (module Harbour is not available)" ==
               error.message
    end

    test "reports the error message when explicitly specified" do
      exception_keyword_list = [
        type: "SomeAwfulError",
        message: "something really bad happened"
      ]

      assert %Payload{errors: [%{message: "something really bad happened"}]} =
               Payload.new(exception_keyword_list, @stacktrace)
    end

    # NOTE: turning a stacktrace into a backtrace is tested in more depth with
    # Airbrake.Payload.Backtrace
    test "it generates correct stacktraces when the current file was a script" do
      stacktrace = [
        {Harbour, :cats, [3], []},
        {:timer, :tc, 1, [file: 'timer.erl', line: 166]}
      ]

      assert %Payload{errors: [error]} = Payload.new(@exception, stacktrace)

      assert [
               %{file: "unknown", function: "Elixir.Harbour.cats(3)", line: 0},
               %{file: "timer.erl", function: ":timer.tc/1", line: 166}
             ] = error.backtrace
    end

    test "reports the notifier" do
      assert %Payload{
               notifier: %{
                 name: "Airbrake Client",
                 url: "https://github.com/CityBaseInc/airbrake_client",
                 version: "0.9.0"
               }
             } = Payload.new(@exception, @stacktrace)
    end

    test "sets a default context" do
      assert %Payload{context: context} = Payload.new(@exception, @stacktrace)
      assert %{environment: _, hostname: _} = context
    end

    test "sets the context when given" do
      context = %{msg: "Potato#cake"}
      assert %Payload{context: context} = Payload.new(@exception, @stacktrace, context: context)
      assert "Potato#cake" == context.msg
    end

    test "sets environment when given :env" do
      env = %{foo: 5, bar: "qux"}
      assert %Payload{environment: ^env} = Payload.new(@exception, @stacktrace, env: env)
    end

    test "sets params when given" do
      params = %{foo: 55, bar: "qux"}
      assert %Payload{params: ^params} = Payload.new(@exception, @stacktrace, params: params)
    end

    test "filters sensitive params" do
      Application.put_env(:airbrake_client, :filter_parameters, ["password"])

      params = %{"password" => "top_secret", "x" => "y"}

      assert %Payload{params: %{"password" => "[FILTERED]", "x" => "y"}} =
               Payload.new(@exception, @stacktrace, params: params)

      Application.delete_env(:airbrake_client, :filter_parameters)
    end

    test "sets session when given" do
      session = %{foo: 555, bar: "qux"}
      assert %Payload{session: ^session} = Payload.new(@exception, @stacktrace, session: session)
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
