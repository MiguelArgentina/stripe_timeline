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

  # Returns a hash with :label, :badge (Bootstrap class), and :dot (our CSS class)
  #
  # NOTE: With only TransactionSummary we cannot perfectly tell full vs partial.
  # We use a practical heuristic:
  # - amt > 0   : collected
  # - amt == 0  : fully refunded (net zero)
  # - amt < 0   : refunded (likely partial)  => mint
  # - explicit dispute status               => amber
  # - explicit failed/required              => gray
  #
  # If you want exact “full vs partial”, see the note at the bottom.
  def tx_visual_for_row(t)
    amt = t.amount_integer.to_i
    st  = t.status.to_s

    return { label: "disputed", badge: "text-bg-warning", dot: "tx-status-warning" } if st.include?("dispute")

    if %w[requires_payment_method requires_action canceled failed].include?(st)
      return { label: st, badge: "text-bg-secondary", dot: "tx-status-secondary" }
    end

    # Refund shape by net amount
    if amt == 0
      return { label: "refunded", badge: "text-bg-danger", dot: "tx-status-danger" }
    elsif amt < 0
      return { label: "partial refund", badge: "badge-mint", dot: "tx-status-partial" }
    end

    # Default collected
    label = st.presence || "succeeded"
    { label:, badge: "text-bg-success", dot: "tx-status-success" }
  end

  # Cache last charge amount per tx during the request
  def latest_charge_amount_cents_for(key)
    @latest_charge_amount_cache ||= {}
    return @latest_charge_amount_cache[key] if @latest_charge_amount_cache.key?(key)

    ev = StripeEvent
           .where(tenant: Current.tenant, transaction_key: key, type_name: "charge.succeeded")
           .order(:created_at_unix)
           .last

    amt = ev&.payload&.dig("data", "object", "amount").to_i
    @latest_charge_amount_cache[key] = (amt > 0 ? amt : nil)
  end

  # NEW: drive the chip from money direction first; status second
  # Returns [label, chip_class, dot_class]
  def tx_summary_badge(t)
    cents = t.amount_integer.to_i
    charge_cents = latest_charge_amount_cents_for(t.transaction_key)

    # 1) Any negative amount = money going out → refund bucket
    if cents < 0
      # tolerance to avoid off-by-1s from test data
      tol = 1
      if charge_cents && cents.abs >= (charge_cents - tol)
        return ["refunded",       "chip-refund-full",    "tx-status-refund-full"]   # FULL refund (light red)
      else
        return ["partial refund", "chip-refund-partial", "tx-status-refund-partial"] # PARTIAL refund (mint/greenish)
      end
    end

    # 2) Disputes (chargebacks) = stronger red
    case t.status.to_s
    when "disputed"
      return ["dispute", "chip-dispute", "tx-status-dispute"]
    when "succeeded"
      return ["succeeded", "chip-success", "tx-status-success"]
    else
      return [t.status.to_s.presence || "—", "chip-neutral", "tx-status-secondary"]
    end
  end
end
