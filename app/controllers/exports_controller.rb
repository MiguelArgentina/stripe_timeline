# app/controllers/exports_controller.rb
require "csv"
class ExportsController < ApplicationController
  def daily
    day = params[:day].present? ? Date.parse(params[:day]) : Date.today
    start_u = day.beginning_of_day.to_i
    end_u   = day.end_of_day.to_i

    events = StripeEvent.where(created_at_unix: start_u..end_u)
    rows = aggregate(events)
    send_data to_csv(rows), filename: "stripe_export_#{day}.csv", type: "text/csv"
  end

  def aggregate(events)
    sums = Hash.new { |h,k| h[k] = { gross:0, refunded:0, held:0, reinstated:0 } }
    events.each do |e|
      o = e.payload["data"]["object"] || {}
      k = e.transaction_key || "unknown"
      case o["object"]
      when "charge"         then sums[k][:gross]      += o["amount"].to_i
      when "refund"         then sums[k][:refunded]   += o["amount"].to_i
      when "dispute_funds"
        amt = o["amount"].to_i
        amt < 0 ? sums[k][:held] += -amt : sums[k][:reinstated] += amt
      end
    end
    sums.map { |k,v| v.merge(key:k, net: v[:gross]-v[:refunded]-v[:held]+v[:reinstated]) }
  end

  def to_csv(rows)
    CSV.generate do |csv|
      csv << %w[key gross refunded held reinstated net]
      rows.each { |r| csv << [r[:key], r[:gross], r[:refunded], r[:held], r[:reinstated], r[:net]] }
    end
  end

  def export
    key = params[:key]
    events = StripeEvent.where(transaction_key: key).order(:created_at_unix)

    csv = CSV.generate do |csv|
      csv << %w[
        transaction_key event_type created_at livemode account
        object object_id amount currency status reason
        charge_id payment_intent_id refund_id dispute_id balance_tx_id source
      ]
      events.each do |e|
        o = e.payload["data"]["object"] || {}
        created_iso = Time.at(e.created_at_unix).utc.strftime("%Y-%m-%dT%H:%M:%SZ")

        csv << [
          key,
          e.type_name,
          created_iso,
          e.livemode,
          e.account,
          o["object"],
          o["id"],
          (o["amount"] || o["amount_paid"]),
          o["currency"],
          o["status"],
          (o["reason"] || o.dig("evidence", "reason")),
          (o["charge"] || o.dig("charges","data",0,"id")),
          (o["payment_intent"] || (o["object"]=="payment_intent" ? o["id"] : nil)),
          (o["object"]=="refund" ? o["id"] : nil),
          (o["object"]=="dispute" ? o["id"] : nil),
          (o["balance_transaction"] || o["balance_transaction_id"]),
          e.source
        ]
      end
    end

    send_data csv, filename: "timeline_#{key}.csv", type: "text/csv"
  end

  # Export the current index list (after filters) as CSV
  def export_index
    scope = TransactionSummary.order(last_event_at_unix: :desc)
    scope = scope.where(status: params[:status]) if params[:status].present?
    if params[:from].present? && params[:to].present?
      from = Time.parse(params[:from]).beginning_of_day.to_i
      to   = Time.parse(params[:to]).end_of_day.to_i
      scope = scope.where(last_event_at_unix: from..to)
    end
    summaries = scope.limit(1000) # cap to something sane

    csv = CSV.generate do |csv|
      csv << %w[key amount currency status last_event_at email order_id last4 livemode]
      summaries.each do |t|
        created_iso = Time.at(t.last_event_at_unix).utc.strftime("%Y-%m-%dT%H:%M:%SZ") if t.last_event_at_unix
        csv << [
          t.transaction_key,
          t.amount_integer,
          t.currency,
          t.status,
          created_iso,
          t.try(:email),
          t.try(:order_id),
          t.try(:last4),
          t.try(:livemode)
        ]
      end
    end

    send_data csv, filename: "transactions_export.csv", type: "text/csv"
  end

end
