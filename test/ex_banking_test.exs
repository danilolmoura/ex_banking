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
    username = "user deposit"
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

    username2 = "user deposit 2"
    assert ExBanking.create_user(username2) == :ok
    assert ExBanking.deposit(username2, 0.0, "real") == {:ok, 0.0}

    # assert ExBanking.deposit(username2, 10.0, "real") == {:error, :too_many_requests_to_user}
  end

  test "withdraw" do
    username = "user withdraw"
    amount = 100.1
    currency = "real"

    assert ExBanking.deposit("user that does not exist", amount, currency) == {:error, :user_does_not_exist}

    assert ExBanking.create_user(username) == :ok
    assert ExBanking.deposit(username, amount, currency) == {:ok, amount}
    assert ExBanking.withdraw(username, 10.0, currency) == {:ok, 90.1}
    assert ExBanking.withdraw(username, 15.0, currency) == {:ok, 75.1}
    assert ExBanking.withdraw(username, 5.0, currency) == {:ok, 70.1}
    assert ExBanking.withdraw(username, 10.0, currency) == {:ok, 60.1}

    assert ExBanking.withdraw(username, 1_200.0, currency) == {:error, :not_enough_money}

    assert ExBanking.withdraw(1, 10.0, "real") == {:error, :wrong_arguments}
    assert ExBanking.withdraw("danilo", 1, "real") == {:error, :wrong_arguments}
    assert ExBanking.withdraw("danilo", "1", "real") == {:error, :wrong_arguments}
    assert ExBanking.withdraw("danilo", -1.0, "real") == {:error, :wrong_arguments}
    assert ExBanking.withdraw("danilo", 10.0, 1) == {:error, :wrong_arguments}

    username2 = "user withdraw 2"
    assert ExBanking.create_user(username2) == :ok
    assert ExBanking.withdraw(username2, 0.0, "real") == {:error, :not_enough_money}
    assert ExBanking.deposit(username2, 100.0, "real") == {:ok, 100.0}
    assert ExBanking.withdraw(username2, 100.0, "real") == {:ok, 0.0}
    assert ExBanking.deposit(username2, 100.0, "real") == {:ok, 100.0}
    assert ExBanking.withdraw(username2, 20.43, "real") == {:ok, 79.57}

    # assert ExBanking.withdraw(username2, 10.0, "real") == {:error, :too_many_requests_to_user}
  end


  test "balance" do
    username = "user balance"
    amount = 100.01
    currency = "real"

    assert ExBanking.balance("user that does not exist", currency) == {:error, :user_does_not_exist}

    assert ExBanking.create_user(username) == :ok
    assert ExBanking.deposit(username, amount, currency) == {:ok, amount}
    assert ExBanking.balance(username, currency) == {:ok, 100.01}

    assert ExBanking.balance(1, "real") == {:error, :wrong_arguments}
    assert ExBanking.balance("danilo", 1) == {:error, :wrong_arguments}
    assert ExBanking.balance("danilo",  :real) == {:error, :wrong_arguments}

    # assert ExBanking.withdraw(username2, 10.0, "real") == {:error, :too_many_requests_to_user}
  end
end
