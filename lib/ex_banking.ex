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
    case GenServer.call(:user_lookup, {:withdraw, user, amount, currency}) do
      {:ok, new_balance} -> {:ok, new_balance}
      :not_enough_money -> {:error, :not_enough_money}
      :user_does_not_exist -> {:error, :user_does_not_exist}
    end
  end

  def withdraw(_, _, _), do: {:error, :wrong_arguments}

  # @spec get_balance(user :: String.t, currency :: String.t) :: {:ok, balance :: number} | {:error, :wrong_arguments | :user_does_not_exist | :too_many_requests_to_user}
  # def get_balance(user, currency) when validate_params(user, currency) do
  #   case GenServer.call(:user_lookup, {:get_balance, user, currency}) do
  #     {:ok, new_balance} -> {:ok, new_balance}
  #     :user_does_not_exist -> {:error, :user_does_not_exist}
  #   end
  # end

  # def get_balance(_, _), do: {:error, :wrong_arguments}

  defp lookup(table, user) do
    case :ets.lookup(table, user) do
      [{^user, %{} = wallet}] -> {:ok, user, wallet}
      [] -> :error
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
        case Enum.empty?(wallet) do
          true ->
            insert(user_table, user, %{currency => amount})
            {:reply, {:ok, amount}, {user_table, refs}}
          false ->
            new_wallet =
              wallet
              |> Map.update(currency, amount, fn existing_value -> sum([existing_value, amount]) end)

            insert(user_table, user, new_wallet)
            {:reply, {:ok, Map.get(new_wallet, currency)}, {user_table, refs}}
        end
      :error ->
        {:reply, :user_does_not_exist, {user_table, refs}}
    end
  end

  @impl true
  def handle_call({:withdraw, user, amount, currency}, _from, {user_table, refs}) do
    lookup(user_table, user)

    case lookup(user_table, user) do

      {:ok, user, wallet} ->
        case Enum.empty?(wallet) do
          true ->
            {:reply, :not_enough_money, {user_table, refs}}
          false ->
            current_balance = Map.get(wallet, currency, 0)

            case substract(current_balance, amount) do
              new_balance when new_balance < 0 ->
                {:reply, :not_enough_money, {user_table, refs}}
              new_balance ->
                insert(user_table, user, Map.put(wallet, currency, new_balance))
                {:reply, {:ok, new_balance}, {user_table, refs}}
            end
        end

      :error ->
        {:reply, :user_does_not_exist, {user_table, refs}}
    end
  end

  # @impl true
  # def handle_call({:get_balance, user, currency}, _from, {user_table, refs}) do
  #   case lookup(user_table, user, currency) do
  #     {:ok, _user, _, balance} ->
  #       {:reply, {:ok, balance}, {user_table, refs}}
  #     :error ->
  #       {:reply, :user_does_not_exist, {user_table, refs}}
  #   end
  # end
end
