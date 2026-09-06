# frozen_string_literal: true

RSpec.describe PaulieLombardo do
  describe ".bouncer" do
    let(:dossier) { instance_double(described_class::Dossier, target: :target, data: { request_hash: "request_hash" }) }

    it "creates Dossier instance" do
      allow(described_class::Dossier).to receive(:new) { dossier }
      allow(described_class::Consigliere).to receive(:new) { double(approve?: false) }

      described_class.bouncer("cntrl", "target") { :ok }
      expect(described_class::Dossier).to have_received(:new).with("cntrl", "target")
    end

    it "creates Consigliere instance" do
      allow(described_class::Dossier).to receive(:new) { dossier }
      allow(described_class::Consigliere).to receive(:new) { double(approve?: false) }

      described_class.bouncer("cntrl", "target") { :ok }
      expect(described_class::Consigliere).to have_received(:new).with(dossier)
    end

    it "consigliere does not approve" do
      allow(described_class::Dossier).to receive(:new) { dossier }
      allow(described_class::Consigliere).to receive(:new) { double(approve?: false) }

      described_class.bouncer("cntrl", "target") { :ok }
      expect(dossier).not_to have_received(:data)
    end

    it "raises a 'no block given' LocalJumpError when called without a block" do
      allow(described_class::Dossier).to receive(:new) { dossier }
      allow(described_class::Consigliere).to receive(:new) { double(approve?: true) }

      expect { described_class.bouncer("cntrl", "target") }.to raise_error(LocalJumpError, /no block given/)
    end

    it "consigliere approve" do
      allow(described_class::Dossier).to receive(:new) { dossier }
      allow(described_class::Consigliere).to receive(:new) { double(approve?: true) }

      described_class.bouncer("cntrl", "target") { nil }
      expect(dossier).to have_received(:data)
    end

    it "yields target to the block" do
      allow(described_class::Dossier).to receive(:new) { dossier }
      allow(described_class::Consigliere).to receive(:new) { double(approve?: true) }

      yielded_target = nil
      described_class.bouncer("ctrl", "target") do |target, _|
        yielded_target = target
        nil
      end

      expect(yielded_target).to eq(dossier.target)
    end

    it "yields dossier.data to the block" do
      allow(described_class::Dossier).to receive(:new) { dossier }
      allow(described_class::Consigliere).to receive(:new) { double(approve?: true) }

      yielded_data = nil
      described_class.bouncer("ctrl", "target") do |_, data|
        yielded_data = data
        nil
      end

      expect(yielded_data).to eq(dossier.data)
    end

    it "returns created paulie_note" do
      allow(described_class::Dossier).to receive(:new) { dossier }
      allow(described_class::Consigliere).to receive(:new) { double(approve?: true) }

      target = create(:post)
      result = described_class.bouncer("ctrl", "target") do |_, _|
        create(:paulie_note, noteable: target)
      end

      expect(result).to eq(target)
    end

    it "returns existing target if record not created" do
      allow(described_class::Dossier).to receive(:new) { dossier }
      allow(described_class::Consigliere).to receive(:new) { double(approve?: true) }

      result = described_class.bouncer("ctrl", "target") do |_, _|
        nil
      end

      expect(result).to eq(dossier.target)
    end
  end
end
