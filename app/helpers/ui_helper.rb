module UiHelper
  def status_badge(status)
    ctx = {
            "succeeded"               => "success",
            "refunded"                => "danger",
            "disputed"                => "warning",
            "requires_payment_method" => "secondary"
          }[status.to_s] || "secondary"
    content_tag(:span, status, class: "badge rounded-pill text-bg-#{ctx}")
  end

  def stat_badge(label, value, context:)
    content_tag(:span, class: "badge text-bg-#{context} me-2") do
      safe_join([label, " ", content_tag(:strong, value)])
    end
  end
end
