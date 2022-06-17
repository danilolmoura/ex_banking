defmodule ExBanking do
  @moduledoc """
  Documentation for `ExBanking`.
  """

  use GenServer

  # Client

  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end


  @spec create_user(user :: String.t) :: :ok | {:error, :wrong_arguments | :user_already_exists}
  def create_user(user) do
    GenServer.call(__MODULE__, {:create_user, user})
  end

  # Server (callbacks)

  @impl true
  def init(users) do
    {:ok, users}
  end

  @impl true
  def handle_call({:create_user, user}, from, state) do
    IO.inspect(user, label: "1")
    IO.inspect(from, label: "2")
    IO.inspect(state, label: "3")
  end
end
