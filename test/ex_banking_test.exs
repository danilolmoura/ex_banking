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
    currency_real = "real"
    currency_euro = "euro"

    assert ExBanking.deposit("user that does not exist", amount, currency_real) == {:error, :user_does_not_exist}

    assert ExBanking.create_user(username) == :ok
    assert ExBanking.deposit(username, amount, currency_real) == {:ok, 100.01}
    assert ExBanking.deposit(username, 25.1, currency_real) == {:ok, 125.11}
    assert ExBanking.deposit(username, 22.32, currency_real) == {:ok, 147.43}
    assert ExBanking.deposit(username, 25.55, currency_real) == {:ok, 172.98}

    assert ExBanking.deposit(username, 25.55, currency_euro) == {:ok, 25.55}
    assert ExBanking.deposit(username, 25.55, currency_euro) == {:ok, 51.10}

    assert ExBanking.deposit(username, 10.0, currency_real) == {:ok, 182.98}
    assert ExBanking.deposit(username, 10.0, currency_euro) == {:ok, 61.10}

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
    currency_real = "real"
    currency_euro = "euro"

    assert ExBanking.deposit("user that does not exist", amount, currency_real) == {:error, :user_does_not_exist}

    assert ExBanking.create_user(username) == :ok
    assert ExBanking.deposit(username, amount, currency_real) == {:ok, amount}
    assert ExBanking.withdraw(username, 10.0, currency_real) == {:ok, 90.1}
    assert ExBanking.withdraw(username, 15.0, currency_real) == {:ok, 75.1}
    assert ExBanking.withdraw(username, 5.0, currency_real) == {:ok, 70.1}
    assert ExBanking.withdraw(username, 10.1, currency_real) == {:ok, 60.0}

    assert ExBanking.withdraw(username, 1_200.0, currency_real) == {:error, :not_enough_money}

    assert ExBanking.deposit(username, amount, currency_euro) == {:ok, amount}
    assert ExBanking.withdraw(username, 30.1, currency_euro) == {:ok, 70.0}
    assert ExBanking.withdraw(username, 30.0, currency_euro) == {:ok, 40.0}

    assert ExBanking.withdraw(username, 200_200.0, currency_euro) == {:error, :not_enough_money}

    assert ExBanking.withdraw(username, 5.0, currency_real) == {:ok, 55.0}
    assert ExBanking.withdraw(username, 5.0, currency_euro) == {:ok, 35.0}
    assert ExBanking.withdraw(username, 5.0, currency_real) == {:ok, 50.0}
    assert ExBanking.withdraw(username, 5.0, currency_euro) == {:ok, 30.0}

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


  test "get_balance" do
    username = "user get_balance"
    amount = 100.01
    currency_real = "real"
    currency_euro = "euro"

    assert ExBanking.get_balance("user that does not exist", currency_real) == {:error, :user_does_not_exist}

    assert ExBanking.create_user(username) == :ok
    assert ExBanking.deposit(username, amount, currency_real) == {:ok, amount}
    assert ExBanking.get_balance(username, currency_real) == {:ok, 100.01}
    assert ExBanking.deposit(username, amount, currency_euro) == {:ok, amount}
    assert ExBanking.get_balance(username, currency_euro) == {:ok, 100.01}

    assert ExBanking.get_balance(username, "bitcoin") == {:ok, 0.0}

    assert ExBanking.get_balance(1, "real") == {:error, :wrong_arguments}
    assert ExBanking.get_balance("danilo", 1) == {:error, :wrong_arguments}
    assert ExBanking.get_balance("danilo",  :real) == {:error, :wrong_arguments}

    # assert ExBanking.withdraw(username2, 10.0, "real") == {:error, :too_many_requests_to_user}
  end
end
