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
end
