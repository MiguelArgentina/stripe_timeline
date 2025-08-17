namespace :stripe do
  desc "Backfill /v1/events (~30 days)"
  task backfill: :environment do
    starting_after = nil
    loop do
      list = Stripe::Event.list(limit: 100, starting_after: starting_after)
      break if list.data.empty?
      list.data.each do |evt|
        rec = StripeEvent.find_or_initialize_by(stripe_id: evt.id)
        next unless rec.new_record?
        rec.assign_attributes(
          type_name: evt.type, api_version: evt.api_version,
          account: (evt.respond_to?(:account) ? evt.account.to_s : ''),
          livemode: evt.livemode, created_at_unix: evt.created,
          payload: evt.to_hash, source: "backfill",
          transaction_key: TransactionKey.compute(evt)
        )
        rec.save!
        ProcessStripeEventJob.perform_later(rec.id)
      end
      starting_after = list.data.last.id
    end
  end
end
