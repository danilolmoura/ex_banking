defmodule ExBanking do
  @moduledoc """
  Documentation for `ExBanking`.
  """

  use GenServer

  import Type

  ### Client API / Helper functions

  @doc """
  Starts the ex_banking with the given options.

  `:name` is always required.
  """
  def start_link(opts) do
    server = Keyword.fetch!(opts, :name)
    GenServer.start_link(__MODULE__, server, opts)
  end

  @spec create_user(user :: String.t()) :: :ok | {:error, :wrong_arguments | :user_already_exists}
  def create_user(user) when validate_params(user) do
    case GenServer.call(:user_lookup, {:create_user, user}) do
      :ok -> :ok
      :user_already_exists -> {:error, :user_already_exists}
    end
  end

  def create_user(_), do: {:error, :wrong_arguments}

  @spec deposit(user :: String.t(), amount :: number, currency :: String.t()) ::
          {:ok, new_balance :: number}
          | {:error, :wrong_arguments | :user_does_not_exist | :too_many_requests_to_user}
  def deposit(user, amount, currency) when validate_params(user, amount, currency) do
    case GenServer.call(:user_lookup, {:deposit, user, amount, currency}) do
      {:ok, new_balance} -> {:ok, new_balance}
      :user_does_not_exist -> {:error, :user_does_not_exist}
    end
  end

  def deposit(_, _, _), do: {:error, :wrong_arguments}

  @spec withdraw(user :: String.t(), amount :: number, currency :: String.t()) ::
          {:ok, new_balance :: number}
          | {:error,
             :wrong_arguments
             | :user_does_not_exist
             | :not_enough_money
             | :too_many_requests_to_user}
  def withdraw(user, amount, currency) when validate_params(user, amount, currency) do
    case GenServer.call(:user_lookup, {:withdraw, user, amount, currency}) do
      {:ok, new_balance} -> {:ok, new_balance}
      :not_enough_money -> {:error, :not_enough_money}
      :user_does_not_exist -> {:error, :user_does_not_exist}
    end
  end

  def withdraw(_, _, _), do: {:error, :wrong_arguments}

  @spec get_balance(user :: String.t(), currency :: String.t()) ::
          {:ok, balance :: number}
          | {:error, :wrong_arguments | :user_does_not_exist | :too_many_requests_to_user}
  def get_balance(user, currency) when validate_params(user, currency) do
    case GenServer.call(:user_lookup, {:get_balance, user, currency}) do
      {:ok, new_balance} -> {:ok, new_balance}
      :user_does_not_exist -> {:error, :user_does_not_exist}
    end
  end

  def get_balance(_, _), do: {:error, :wrong_arguments}

  @spec send(
          from_user :: String.t(),
          to_user :: String.t(),
          amount :: number,
          currency :: String.t()
        ) ::
          {:ok, from_user_balance :: number, to_user_balance :: number}
          | {:error,
             :wrong_arguments
             | :not_enough_money
             | :sender_does_not_exist
             | :receiver_does_not_exist
             | :too_many_requests_to_sender
             | :too_many_requests_to_receiver}
  def send(from_user, to_user, amount, currency)
      when validate_params(from_user, to_user, amount, currency) do
    case GenServer.call(:user_lookup, {:send, from_user, to_user, amount, currency}) do
      {:ok, from_user_balance, to_user_balance} -> {:ok, from_user_balance, to_user_balance}
      :not_enough_money -> {:error, :not_enough_money}
      :sender_does_not_exist -> {:error, :sender_does_not_exist}
      :receiver_does_not_exist -> {:error, :receiver_does_not_exist}
    end
  end

  def send(_, _, _, _), do: {:error, :wrong_arguments}

  defp lookup(table, user) do
    case :ets.lookup(table, user) do
      [{^user, %{} = wallet}] -> {:ok, user, wallet}
      [] -> :error
    end
  end

  defp lookup(table, user, default_error) do
    case lookup(table, user) do
      {:ok, user, wallet} -> {:ok, user, wallet}
      :error -> default_error
    end
  end

  defp insert(table, user), do: insert(table, user, %{})
  defp insert(table, user, wallet), do: :ets.insert(table, {user, wallet})

  def sum(enum) do
    enum
    |> Enum.sum()
    |> Float.round(2)
  end

  def substract(balance, value) do
    balance
    |> Kernel.-(value)
    |> Float.round(2)
  end

  def withdraw(user_table, user, wallet, currency, amount) do
    case Enum.empty?(wallet) do
      true ->
        {:error, :not_enough_money}

      false ->
        current_balance = Map.get(wallet, currency, 0)

        case substract(current_balance, amount) do
          new_balance when new_balance < 0 ->
            {:error, :not_enough_money}

          new_balance ->
            insert(user_table, user, Map.put(wallet, currency, new_balance))
            {:ok, new_balance}
        end
    end
  end

  def deposit(user_table, user, wallet, currency, amount) do
    case Enum.empty?(wallet) do
      true ->
        insert(user_table, user, %{currency => amount})
        {:ok, amount}

      false ->
        new_wallet =
          wallet
          |> Map.update(currency, amount, fn existing_value -> sum([existing_value, amount]) end)

        insert(user_table, user, new_wallet)
        {:ok, Map.get(new_wallet, currency)}
    end
  end

  ### GenServer API
  @impl true
  def init(table) do
    user_table = :ets.new(table, [:set, :protected, :named_table, read_concurrency: true])
    refs = %{}
    {:ok, {user_table, refs}}
  end

  @impl true
  def handle_call({:create_user, user}, _from, {user_table, refs}) do
    case lookup(user_table, user) do
      {:ok, _user, _wallet} ->
        {:reply, :user_already_exists, {user_table, refs}}

      :error ->
        insert(user_table, user)
        {:reply, :ok, {user_table, refs}}
    end
  end

  @impl true
  def handle_call({:deposit, user, amount, currency}, _from, {user_table, refs}) do
    case lookup(user_table, user) do
      {:ok, user, wallet} ->
        {:reply, deposit(user_table, user, wallet, currency, amount), {user_table, refs}}

      :error ->
        {:reply, :user_does_not_exist, {user_table, refs}}
    end
  end

  @impl true
  def handle_call({:withdraw, user, amount, currency}, _from, {user_table, refs}) do
    case lookup(user_table, user) do
      {:ok, user, wallet} ->
        case withdraw(user_table, user, wallet, currency, amount) do
          {:error, :not_enough_money} ->
            {:reply, :not_enough_money, {user_table, refs}}

          {:ok, new_balance} ->
            {:reply, {:ok, new_balance}, {user_table, refs}}
        end

      :error ->
        {:reply, :user_does_not_exist, {user_table, refs}}
    end
  end

  @impl true
  def handle_call({:get_balance, user, currency}, _from, {user_table, refs}) do
    case lookup(user_table, user) do
      {:ok, _user, wallet} ->
        {:reply, {:ok, Map.get(wallet, currency, 0.0)}, {user_table, refs}}

      :error ->
        {:reply, :user_does_not_exist, {user_table, refs}}
    end
  end

  @impl true
  def handle_call({:send, from_user, to_user, amount, currency}, _from, {user_table, refs}) do
    with {:ok, from_user, from_user_wallet} <-
           lookup(user_table, from_user, :sender_does_not_exist),
         {:ok, to_user, to_user_wallet} <- lookup(user_table, to_user, :receiver_does_not_exist),
         {:ok, from_user_balance} <-
           withdraw(user_table, from_user, from_user_wallet, currency, amount),
         {:ok, to_user_balance} <- deposit(user_table, to_user, to_user_wallet, currency, amount) do
      {:reply, {:ok, from_user_balance, to_user_balance}, {user_table, refs}}
    else
      {:error, :not_enough_money} ->
        {:reply, :not_enough_money, {user_table, refs}}

      :sender_does_not_exist ->
        {:reply, :sender_does_not_exist, {user_table, refs}}

      :receiver_does_not_exist ->
        {:reply, :receiver_does_not_exist, {user_table, refs}}
    end
  end
end
