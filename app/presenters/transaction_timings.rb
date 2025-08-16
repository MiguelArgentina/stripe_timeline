# app/presenters/transaction_timings.rb
class TransactionTimings
  attr_reader :pi_to_charge_ms, :charge_to_refund_ms, :dispute_to_close_ms

  def initialize(events)
    events = Array(events)

    by = events.index_by(&:type_name)

    pi_created  = by["payment_intent.created"]&.created_at_unix
    ch_succeeded= by["charge.succeeded"]&.created_at_unix
    rf_created  = by["refund.created"]&.created_at_unix
    dp_created  = by["charge.dispute.created"]&.created_at_unix
    dp_closed   = by["charge.dispute.closed"]&.created_at_unix

    @pi_to_charge_ms     = ms(pi_created, ch_succeeded)
    @charge_to_refund_ms = ms(ch_succeeded, rf_created)
    @dispute_to_close_ms = ms(dp_created, dp_closed)
  end

  def human(ms)
    return "—" unless ms
    secs = (ms / 1000.0)
    return "#{secs.round(1)}s" if secs < 120
    mins = (secs / 60).round
    mins < 120 ? "#{mins}m" : "#{(mins/60.0).round(1)}h"
  end

  private
  def ms(a,b); (b - a) * 1000 if a && b; end
end
