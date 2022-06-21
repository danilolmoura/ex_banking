defmodule Type do
  @moduledoc """
  Documentation for `Types`.
  """

  defguard validate_params(user) when is_binary(user)

  defguard validate_params(user, currency) when is_binary(user) and is_binary(currency)

  defguard validate_params(user, amount, currency)
           when is_binary(user) and is_binary(currency) and is_float(amount) and amount >= 0

  defguard validate_params(from_user, to_user, amount, currency)
           when is_binary(from_user) and is_binary(to_user) and is_binary(currency) and
                  is_float(amount) and amount >= 0
end
