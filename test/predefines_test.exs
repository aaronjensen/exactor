defmodule PredefinesTest do
  use ExUnit.Case

  defmodule TolerantServer do
    use ExActor.Tolerant
    defstart start
  end

  test "tolerant" do
    {:ok, pid} = TolerantServer.start
    GenServer.cast(pid, :undefined_message)
    send(pid, :undefined_message)
    assert match?(
      {:timeout, _},
      catch_exit(GenServer.call(pid, :undefined_message, 10))
    )
  end


  defmodule NonStartableStrictServer do
    use ExActor.Strict
  end


  defmodule StrictServer do
    use ExActor.Strict
    defstart start, do: initial_state(nil)
  end

  setup do
    Logger.remove_backend(:console)
    on_exit fn ->
      Logger.add_backend(:console)
    end
  end

  test "strict" do
    assert match?({:error, :badinit}, GenServer.start(NonStartableStrictServer, nil))

    assert_invalid(StrictServer, &GenServer.cast(&1, :undefined_message))
    assert_invalid(StrictServer, &send(&1, :undefined_message))
    assert_invalid(StrictServer,
      fn(pid) ->
        assert match?(
          {{:bad_call, :undefined_message}, _},
          catch_exit(GenServer.call(pid, :undefined_message, 10))
        )
      end
    )
  end

  defp assert_invalid(module, fun) do
    {:ok, pid} = module.start

    fun.(pid)

    :timer.sleep(20)
    assert Process.info(pid) == nil
  end



  defmodule GenServerServer do
    use ExActor.GenServer
    defstart start
  end

  test "gen_server" do
    assert_invalid(GenServerServer, &GenServer.cast(&1, :undefined_message))

    assert_invalid(GenServerServer,
      fn(pid) ->
        send(pid, :undefined_message)

        assert match?(
          {{:bad_call, :undefined_message}, _},
          catch_exit(GenServer.call(pid, :undefined_message, 10))
        )
      end
    )
  end



  defmodule EmptyServer do
    use ExActor.Empty
    defstart start

    def init(args), do: { :ok, args }
    def handle_call(_msg, _from, state), do: {:reply, 1, state}
    def handle_info(_msg, state), do: {:noreply, state}
    def handle_cast(_msg, state), do: {:noreply, state}
    def terminate(_reason, _state), do: :ok
    def code_change(_old, state, _extra), do: { :ok, state }
  end

  test "empty" do
    {:ok, pid} = EmptyServer.start
    GenServer.cast(pid, :undefined_message)
    send(pid, :undefined_message)
    assert GenServer.call(pid, :undefined_message) == 1
  end
end