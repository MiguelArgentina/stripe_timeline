# app/controllers/transactions_controller.rb
class TransactionsController < ApplicationController
  def index
    @status = params[:status].presence
    @from   = parse_date(params[:from])
    @to     = parse_date(params[:to])&.end_of_day
    @q      = params[:q].to_s.strip

    # ALWAYS scope to tenant
    scope = TransactionSummary.where(tenant: Current.tenant)

    scope = scope.where(status: @status) if @status.present?
    scope = scope.where("last_event_at_unix >= ?", @from.to_i) if @from
    scope = scope.where("last_event_at_unix <= ?", @to.to_i) if @to

    if @q.present?
      like = "%#{@q}%"
      scope = scope.where(<<~SQL, like:, like2: like)
        transaction_key ILIKE :like
        OR latest_charge ILIKE :like
        OR email ILIKE :like
        OR order_id ILIKE :like2
        OR customer_id ILIKE :like2
      SQL
    end

    @rows = scope.order(last_event_at_unix: :desc).limit(200)

    # Stats (refunds/disputes are negative in your model)
    gross     = @rows.select { |r| r.amount_integer.to_i > 0 }.sum(&:amount_integer).to_i
    refunds   = @rows.select { |r| r.status == "refunded" }.sum(&:amount_integer).to_i
    disputed  = @rows.select { |r| r.status == "disputed" }.sum(&:amount_integer).to_i
    net       = gross + refunds + disputed

    @stats = {
      count:    @rows.size,
      gross:    gross,
      refunds:  refunds,
      disputed: disputed,
      net:      net,
      currency: detect_currency(@rows)
    }
  end

  def show
    @key    = params[:key]
    @events = StripeEvent.where(tenant: Current.tenant, transaction_key: @key).order(:created_at_unix)
    @groups = @events.group_by { |e| family(e.type_name) }
  end

  def latest
    rec = TransactionSummary.where(tenant: Current.tenant).order(last_event_at_unix: :desc).first
    if rec
      redirect_to transaction_path(key: rec.transaction_key)
    else
      redirect_to root_path, notice: "No transactions yet."
    end
  end

  def clear
    render layout: false
  end

  private

  def family(type)
    case type
    when /\Apayment_intent\./  then "Payment"
    when /\Acharge\./          then "Charge"
    when /\Arefund\./          then "Refund"
    when /\Adispute\./         then "Dispute"
    when /\Ainvoice\./         then "Invoice"
    when /\Acheckout\.session/ then "Checkout"
    else "Other"
    end
  end

  def parse_date(s)
    return nil if s.blank?
    Time.zone.parse(s) rescue nil
  end

  # crude but works for single-currency test mode; improve later for multi-currency
  def detect_currency(rows)
    rows.find { |r| r.currency.present? }&.currency || "usd"
  end
end
