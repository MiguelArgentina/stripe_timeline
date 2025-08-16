module CurrencyHelper
  SYMBOL = { "usd" => "$", "eur" => "€", "gbp" => "£" }.freeze
  def money_cents(amount_integer, currency)
    return "-" unless amount_integer && currency
    number_to_currency(amount_integer.to_i / 100.0,
                       unit: (SYMBOL[currency] || "#{currency&.upcase} "))
  end
end
