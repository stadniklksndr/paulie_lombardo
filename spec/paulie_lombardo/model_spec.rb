# frozen_string_literal: true

RSpec.describe PaulieLombardo::Model do
  let(:dummy_class) do
    Class.new do
      def self.has_many(*args, **kwargs); end

      include PaulieLombardo::Model
    end
  end

  describe ".has_paulie_notes" do
    it "defines has_many association for paulie_notes" do
      allow(dummy_class).to receive(:has_many)

      dummy_class.has_paulie_notes
      expect(dummy_class).to have_received(:has_many).with(
        :paulie_notes, as: :noteable, dependent: :delete_all
      )
    end

    it "defines paulie_notes_options" do
      dummy_class.has_paulie_notes
      expect(dummy_class.paulie_notes_options[:interval]).to be_nil
    end

    it "defines :daily interval" do
      dummy_class.has_paulie_notes interval: :daily
      expect(dummy_class.paulie_notes_options[:interval]).to eq(:daily)
    end
  end
end
