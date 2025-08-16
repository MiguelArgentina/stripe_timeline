module UiHelper
  def status_chip(status)
    klass =
      case status.to_s
      when "succeeded"                then "success"
      when "refunded"                 then "refund"
      when "disputed", "warning"      then "warning"
      when "requires_payment_method"  then "muted"
      else "muted"
      end
    content_tag(:span, status, class: "chip #{klass}")
  end
end
