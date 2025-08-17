# app/helpers/application_helper.rb
module ApplicationHelper
  STATUS_TO_BOOTSTRAP = {
    "succeeded"                => "success",
    "requires_payment_method"  => "secondary",
    "refunded"                 => "info",
    "disputed"                 => "warning"
  }.freeze

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

  def id_chip(text)
    content_tag :span, text, class: "id-chip mono", data: { controller: "copy", copy_target: "source" }
  end

  # Map our statuses to Bootstrap context colors
  def status_color(status)
    case status.to_s
    when "succeeded", "paid", "complete"            then "success"   # green
    when "refunded"                                  then "info"      # blue
    when "disputed", "requires_action",
      "requires_confirmation"                     then "warning"   # yellow
    when "failed", "payment_failed", "unpaid"        then "danger"    # red
    when "canceled", "requires_payment_method", ""   then "secondary" # gray
    else "secondary"
    end
  end

  # Render a small Bootstrap badge chip for status
  def status_chip(status, bootstrap: false)
    text  = status.to_s.presence || "unknown"
    color = status_color(status)
    if bootstrap
      content_tag(:span, text, class: "badge text-bg-#{color}")
    else
      content_tag(:span, text, class: "chip #{color}")
    end
  end

  def status_dot_class(status)
    case status.to_s
    when "succeeded"                 then "tx-status-success"
    when "refunded", "failed"        then "tx-status-danger"
    when "disputed", "requires_action",
      "requires_payment_method"   then "tx-status-warning"
    else                                   "tx-status-secondary"
    end
  end
end
