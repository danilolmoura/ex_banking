defmodule Type do
  @moduledoc """
  Documentation for `Types`.
  """

  defguard validate_params(user) when is_binary(user)

  defguard validate_params(user, amount, currency) when is_binary(user) and is_binary(currency) and is_float(amount) and amount >= 0
end
