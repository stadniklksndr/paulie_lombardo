# frozen_string_literal: true

# Represents a non-ActiveRecord target for polymorphic `PaulieNote` associations
class PaulieStaticPage
  attr_reader :id

  def initialize(name)
    @id = name.to_s.underscore
  end

  def self.polymorphic_name
    name
  end

  # Emulates `has_many :paulie_notes` creation for non-ActiveRecord target
  class AssociationProxy
    def initialize(target)
      @target = target
    end

    def create!(attributes = {})
      PaulieNote.create!(
        attributes.merge(
          noteable_type: @target.class.polymorphic_name,
          noteable_id: @target.id
        )
      )
    end
  end

  def paulie_notes
    AssociationProxy.new(self)
  end

  def paulie_notes_count
    PaulieNote.where(noteable_type: self.class.polymorphic_name, noteable_id: id).count
  end

  # Stubs to prevent SQL execution and NoMethodError for the counter_cache column
  #
  # rubocop:disable-next Style/SingleLineMethods
  # rubocop:disable-next Naming/PredicatePrefix
  class << self
    def unscoped; self; end
    def where!(*); self; end
    def primary_key; :id; end
    def has_query_constraints?; false; end
    def composite_primary_key?; false; end
    def update_counters(*_args); 0 end
  end
end
