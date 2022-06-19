defmodule ExBanking do
  @moduledoc """
  Documentation for `ExBanking`.
  """

  use GenServer

  ### Client API / Helper functions

  @doc """
  Starts the ex_banking with the given options.

  `:name` is always required.
  """
  def start_link(opts) do
    server = Keyword.fetch!(opts, :name)
    GenServer.start_link(__MODULE__, server, opts)
  end

  @spec create_user(user :: String.t) :: :ok | {:error, :wrong_arguments | :user_already_exists}
  def create_user(user) when is_binary(user) do
    case GenServer.call(:user_lookup, {:create_user, user}) do
      :ok -> :ok
      :user_already_exists -> {:error, :user_already_exists}
    end
  end

  def create_user(_), do: {:error, :wrong_arguments}

  defp lookup(table, user) do
    case :ets.lookup(table, user) do
      [{^user}] -> {:ok, user}
      [] -> :error
    end
  end

  defp insert(table, user) do
    case :ets.insert(table, {user}) do
      true -> true
      error -> error
    end
  end

  ### GenServer API
  @impl true
  def init(table) do
    user_table = :ets.new(table, [:set, :protected, :named_table, read_concurrency: true])
    refs  = %{}
    {:ok, {user_table, refs}}
  end

  @impl true
  def handle_call({:create_user, user}, _from, {user_table, refs}) do
    case lookup(user_table, user) do
      {:ok, _user} ->
        {:reply, :user_already_exists, {user_table, refs}}
      :error ->
        case insert(user_table, user) do
          true -> {:reply, :ok, {user_table, refs}}
          _ -> IO.inspect("TODO: Check for some other errors")
            {:reply, :error, {user_table, refs}}
        end
    end
  end
end
