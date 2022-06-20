defmodule ExBankingTest do
  use ExUnit.Case
  doctest ExBanking

  setup context do
    ExBanking.start_link(name: context.test)
    %{exbanking_server: context.test}
  end

  test "create user" do
    username = "user_test"
    assert ExBanking.create_user(username) == :ok
    assert ExBanking.create_user(username) == {:error, :user_already_exists}

    assert ExBanking.create_user(123) == {:error, :wrong_arguments}
    assert ExBanking.create_user(:abc) == {:error, :wrong_arguments}
  end

  test "deposit" do
    username = "user"
    amount = 100.01
    currency = "real"

    assert ExBanking.deposit("user that does not exist", amount, currency) == {:error, :user_does_not_exist}

    assert ExBanking.create_user(username) == :ok
    assert ExBanking.deposit(username, amount, currency) == {:ok, 100.01}
    assert ExBanking.deposit(username, 25.1, currency) == {:ok, 125.11}
    assert ExBanking.deposit(username, 22.32, currency) == {:ok, 147.43}
    assert ExBanking.deposit(username, 25.55, currency) == {:ok, 172.98}

    assert ExBanking.deposit(1, 10.0, "real") == {:error, :wrong_arguments}
    assert ExBanking.deposit("danilo", 1, "real") == {:error, :wrong_arguments}
    assert ExBanking.deposit("danilo", "1", "real") == {:error, :wrong_arguments}
    assert ExBanking.deposit("danilo", -1.0, "real") == {:error, :wrong_arguments}
    assert ExBanking.deposit("danilo", 10.0, 1) == {:error, :wrong_arguments}

    username2 = "other user"
    assert ExBanking.create_user(username2) == :ok
    assert ExBanking.deposit(username2, 0.0, "real") == {:ok, 0.0}
  end
end
