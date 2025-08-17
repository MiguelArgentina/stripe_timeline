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

  def status_chip(status, bootstrap: true)
    s = status.to_s
    label = s.tr("_", " ")

    klass =
      case s
      when "succeeded"               then "badge rounded-pill text-bg-success"
      when "refunded"                then "badge rounded-pill text-bg-info"
      when "disputed"                then "badge rounded-pill text-bg-warning"
      when "requires_payment_method" then "badge rounded-pill text-bg-secondary"
      else                                 "badge rounded-pill text-bg-secondary"
      end

    content_tag(:span, label, class: klass)
  end
end
