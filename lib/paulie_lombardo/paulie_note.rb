# frozen_string_literal: true

# Represents an individual note record associated polymorphically with any model.
class PaulieNote < ActiveRecord::Base
  belongs_to :noteable, polymorphic: true, counter_cache: true

  before_create :set_viewed_on

  def noteable
    if noteable_type == PaulieStaticPage.polymorphic_name
      PaulieStaticPage.new(noteable_id)
    else
      super
    end
  end

  private

  def set_viewed_on
    self.viewed_on ||= Time.current.utc.to_date
  end
end
