class Current < ActiveSupport::CurrentAttributes
  attribute :tenant

  def reset
    self.tenant = nil
  end
end