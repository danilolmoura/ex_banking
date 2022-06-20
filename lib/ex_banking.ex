defmodule ExBanking do
  @moduledoc """
  Documentation for `ExBanking`.
  """

  use GenServer

  import Type, only: [validate_params: 1, validate_params: 3]


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
  def create_user(user) when validate_params(user) do
    case GenServer.call(:user_lookup, {:create_user, user}) do
      :ok -> :ok
      :user_already_exists -> {:error, :user_already_exists}
    end
  end

  def create_user(_), do: {:error, :wrong_arguments}

  @spec deposit(user :: String.t, amount :: number, currency :: String.t) :: {:ok, new_balance :: number} | {:error, :wrong_arguments | :user_does_not_exist | :too_many_requests_to_user}
  def deposit(user, amount, currency) when validate_params(user, amount, currency) do
    case GenServer.call(:user_lookup, {:deposit, user, amount, currency}) do
      {:ok, new_balance} -> {:ok, new_balance}
      :user_does_not_exist -> {:error, :user_does_not_exist}
    end
  end

  def deposit(_, _, _), do: {:error, :wrong_arguments}

  @spec withdraw(user :: String.t, amount :: number, currency :: String.t) :: {:ok, new_balance :: number} | {:error, :wrong_arguments | :user_does_not_exist | :not_enough_money | :too_many_requests_to_user}
  def withdraw(user, amount, currency) when validate_params(user, amount, currency) do
    case GenServer.call(:user_lookup, {:deposit, user, amount, currency}) do
      {:ok, new_balance} -> {:ok, new_balance}
      :user_does_not_exist -> {:error, :user_does_not_exist}
    end
  end

  def withdraw(_, _, _), do: {:error, :wrong_arguments}

  defp lookup(table, user) do
    case :ets.lookup(table, user) do
      [{^user}] -> {:ok, user}
      [{^user, currency, amount}] -> {:ok, user, currency, amount}
      [] -> :error
    end
  end

  defp insert(table, user) do
    case :ets.insert(table, {user}) do
      true ->
        true
      error -> error
    end
  end

  defp insert(table, user, currency, amount) do
    case :ets.insert(table, {user, currency, amount}) do
      true ->
        true
      error -> error
    end
  end

  def sum(enum) do
    enum
    |> Enum.sum()
    |> Float.round(2)
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

  @impl true
  def handle_call({:deposit, user, amount, currency}, _from, {user_table, refs}) do
    case lookup(user_table, user) do
      {:ok, user} ->
        case insert(user_table, user, currency, amount) do
          true -> {:reply, {:ok, amount}, {user_table, refs}}
          _ -> IO.inspect("TODO: Check for some other errors")
        end
      {:ok, user, _, balance} ->
        new_balance = sum([balance, amount])
        case insert(user_table, user, currency, new_balance) do
          true -> {:reply, {:ok, new_balance}, {user_table, refs}}
          _ -> IO.inspect("TODO: Check for some other errors")
        end
      :error ->
        {:reply, :user_does_not_exist, {user_table, refs}}
    end
  end
end
