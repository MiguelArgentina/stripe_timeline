# app/controllers/registrations_controller.rb
class RegistrationsController < ApplicationController
  skip_before_action :require_login,   only: [:new, :create]
  skip_before_action :require_tenant!, only: [:new, :create] rescue nil

  def new; end

  def create
    company   = params.require(:company)
    subdomain = params.require(:subdomain).to_s.downcase
                      .gsub(/[^a-z0-9-]/, "-").gsub(/^-+|-+$/, "")
    email     = params.require(:email)
    password  = params.require(:password)

    if subdomain.blank?
      redirect_to new_registration_path, alert: "Please choose a subdomain" and return
    end

    host = "#{subdomain}.lvh.me" # in prod: "#{subdomain}.yourapp.com"

    # ⛔️ Clear, user-visible availability check (no guessing)
    if Tenant.exists?(primary_domain: host) || Domain.exists?(host: host)
      redirect_to new_registration_path, alert: "That subdomain is already taken" and return
    end

    tenant = nil
    user   = nil

    Tenant.transaction do
      tenant = Tenant.create!(name: company, primary_domain: host)
      tenant.domains.create!(host: host)
      user = tenant.users.create!(email:, password:)
    end

    # one-time short-lived token to set the session on the tenant host
    token  = user.signed_id(purpose: "cross-subdomain-login", expires_in: 10.minutes)
    target = root_url(host: tenant.canonical_host, token:)

    redirect_to target, allow_other_host: true
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error("[signup] #{e.record.class} invalid: #{e.record.errors.full_messages.join(", ")}")
    redirect_to new_registration_path, alert: e.record.errors.full_messages.to_sentence
  rescue ActiveRecord::RecordNotUnique => e
    Rails.logger.error("[signup] not unique: #{e.message}")
    redirect_to new_registration_path, alert: "That subdomain is already taken"
  end
end
