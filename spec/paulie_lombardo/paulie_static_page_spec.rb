# frozen_string_literal: true

RSpec.describe PaulieStaticPage do
  let(:target) { "landing" }
  let(:page) { described_class.new(target) }

  describe ".initialize" do
    context "when build instance" do
      it "set @id variable" do
        expect(page.instance_variable_get(:@id)).to be_present
      end
    end
  end

  describe ".polymorphic_name" do
    it "returns PaulieStaticPage" do
      expect(described_class.polymorphic_name).to eq("PaulieStaticPage")
    end
  end

  describe "#id" do
    context "when target is CamelCase string" do
      let(:target) { "LandingPage" }

      it "converts the name to snake_case" do
        expect(page.id).to eq("landing_page")
      end
    end

    context "when target is :symbol" do
      let(:target) { :contact_us }

      it "converts the name to string" do
        expect(page.id).to eq("contact_us")
      end
    end
  end

  describe "#paulie_notes" do
    it "replace has_many :paulie_notes relation for staic page" do
      allow(described_class::AssociationProxy).to receive(:new).and_return(true)

      page.paulie_notes
      expect(described_class::AssociationProxy).to have_received(:new).with(page)
    end
  end

  describe "#paulie_notes_count" do
    context "when query hit" do
      let(:data) { { noteable_type: "PaulieStaticPage", noteable_id: "landing" } }

      it "includes necessary data" do
        allow(PaulieNote).to receive(:where).and_return(double(count: 0))
        page.paulie_notes_count
        expect(PaulieNote).to have_received(:where).with(data)
      end

      it "returns real count" do
        create(:paulie_note, noteable_type: "PaulieStaticPage", noteable_id: "landing")
        expect(page.paulie_notes_count).to eq(1)
      end
    end
  end

  describe "AssociationProxy" do
    let(:proxy) { described_class::AssociationProxy.new(page) }

    context "when build instance" do
      it "set @target variable" do
        expect(proxy.instance_variable_get(:@target)).to be_present
      end
    end

    context "when call create!" do
      let(:data) do
        {
          request_hash: "request_hash",
          noteable_type: "PaulieStaticPage",
          noteable_id: "landing"
        }
      end

      it "includes attributes" do
        allow(PaulieNote).to receive(:create!).and_return(true)
        proxy.create!(request_hash: "request_hash")
        expect(PaulieNote).to have_received(:create!).with(data)
      end

      it "adds paulie_note" do
        expect { proxy.create!(request_hash: "request_hash") }.to change(PaulieNote, :count).by(1)
      end
    end
  end
end
