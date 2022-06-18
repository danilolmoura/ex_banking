defmodule ExBanking do
  @moduledoc """
  Documentation for `ExBanking`.
  """

  use GenServer

  # Client

  @doc """
  Starts the ex_banking with the given options.

  `:name` is always required.
  """
  def start_link(opts) do
    server = Keyword.fetch!(opts, :name)
    GenServer.start_link(__MODULE__, server, opts)
  end

  @spec create_user(user :: String.t) :: :ok | {:error, :wrong_arguments | :user_already_exists}
  def create_user(user) do
    GenServer.call(__MODULE__, {:create_user, user})
  end

  # Server (callbacks)
  @impl true
  def init(table) do
    names = :ets.new(table, [:named_table])
    refs  = %{}
    {:ok, {names, refs}}
  end

  @impl true
  def handle_call({:create_user, user}, from, state) do
    IO.inspect(user, label: "1")
    IO.inspect(from, label: "2")
    IO.inspect(state, label: "3")
  end
end
