# db/seeds.rb
Tenant.destroy_all
Domain.destroy_all

tenant = Tenant.find_or_create_by!(name: "Demo Merchant") do |t|
  t.primary_domain = "localhost"
  t.webhook_signing_secret = ENV.fetch("STRIPE_WEBHOOK_SECRET", "whsec_test")
end

# Rails' request.host is just the host (no port)
Domain.create!(host: "localhost", tenant:)
Domain.create!(host: "127.0.0.1", tenant:) # nice to have
puts "Seeded Tenant #{tenant.id} with domains localhost / 127.0.0.1"
