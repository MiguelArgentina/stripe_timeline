# app/models/stripe_event.rb
class StripeEvent < ApplicationRecord
  belongs_to :tenant
end


