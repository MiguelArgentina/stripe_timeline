# app/helpers/application_helper.rb
module ApplicationHelper
  def format_cents(cents, currency = "usd")
    return "—" if cents.nil?
    unit = (currency || "usd").upcase
    "#{unit == 'USD' ? '$' : unit}#{'%.2f' % (cents.to_i / 100.0)}"
  end

  def chip_class_for(label)
    case label
    when :gross    then "chip info"
    when :refunds  then "chip refund"
    when :disputed then "chip warn"
    when :net      then "chip success"
    else "chip"
    end
  end
end
