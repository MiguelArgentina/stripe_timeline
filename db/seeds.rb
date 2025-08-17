# db/seeds.rb
User.destroy_all   if defined?(User)
Domain.destroy_all
Tenant.destroy_all

tenant = Tenant.create!(name: "Demo", primary_domain: "demo.lvh.me").tap do |t|
  t.domains.create!(host: t.primary_domain)            # ✅ demo.lvh.me
  t.users.create!(email: "owner@example.com", password: "password")
end

puts "Seeded Tenant #{tenant.id} on #{tenant.primary_domain}"
