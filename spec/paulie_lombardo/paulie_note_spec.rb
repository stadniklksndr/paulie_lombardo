# frozen_string_literal: true

RSpec.describe PaulieNote do
  describe "associations" do
    let(:association) { described_class.reflect_on_association(:noteable) }

    it "belongs to noteable" do
      expect(association.macro).to eq(:belongs_to)
    end

    it "is polymorphic" do
      expect(association.options[:polymorphic]).to be(true)
    end

    it "has counter_cache enabled" do
      expect(association.options[:counter_cache][:active]).to be(true)
    end

    it "uses :paulie_notes_count as counter_cache_column" do
      expect(association.counter_cache_column).to eq("paulie_notes_count")
    end
  end

  describe "callbacks" do
    context "with before_create" do
      it "sets viewed_on to the current UTC date" do
        now = Time.utc(2026, 8, 28, 12, 0, 0)
        allow(Time).to receive(:current).and_return(now)

        note = described_class.new(request_hash: "request_hash", noteable: build(:post))
        note.save!

        expect(note.reload.viewed_on).to eq(now.to_date)
      end
    end
  end

  describe "#noteable" do
    it "returns PaulieStaticPage instance" do
      note = create(:paulie_note, noteable_type: "PaulieStaticPage", noteable_id: "landing")
      expect(note.noteable.class.name).to eq("PaulieStaticPage")
    end

    it "returns real AR instance" do
      note = create(:paulie_note)
      expect(note.noteable.class.name).to eq("Post")
    end
  end
end
