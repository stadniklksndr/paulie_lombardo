# frozen_string_literal: true

RSpec.describe PaulieLombardo::Controller do
  describe "#paulie_note" do
    let(:dummy_class) do
      Class.new do
        include PaulieLombardo::Controller

        attr_accessor :request, :session
      end
    end

    let(:instance) { dummy_class.new }

    context "when rails action call :paulie_note(target)" do
      let(:target) { create(:post) }
      let(:paulie_notes) { double(create!: true) }

      it "runs PaulieLombardo.bouncer" do
        allow(PaulieLombardo).to receive(:bouncer).and_return(true)

        instance.paulie_note(target)
        expect(PaulieLombardo).to have_received(:bouncer).with(instance, target)
      end

      it "target receive :paulie_notes" do
        dossier_data = { some: "data" }
        allow(PaulieLombardo).to receive(:bouncer).and_yield(target, dossier_data)
        allow(target).to receive(:paulie_notes) { paulie_notes }

        instance.paulie_note(target)
        expect(target).to have_received(:paulie_notes)
      end

      it "paulie_notes receive :create with data" do
        dossier_data = { some: "data" }
        allow(PaulieLombardo).to receive(:bouncer).and_yield(target, dossier_data)
        allow(target).to receive(:paulie_notes) { paulie_notes }

        instance.paulie_note(target)
        expect(paulie_notes).to have_received(:create!).with(dossier_data)
      end
    end

    context "when real data comes" do
      let(:target) { create(:post) }

      let(:request) do
        double(
          headers: {
            "HTTP_SEC_CH_UA" => "Chrome",
            "HTTP_SEC_CH_UA_PLATFORM" => "Linux",
            "HTTP_SEC_CH_UA_MOBILE" => "?0"
          },
          env: { warden: nil },
          referrer: "referrer.com",
          remote_ip: "192.168.1.150",
          user_agent: "Mozilla/5.0 (X11; Linux x86_64)",
          accept_language: "uk-UA,uk;q=0.9,en-US;q=0.8"
        )
      end

      let(:session) { double(id: nil) }

      before do
        instance.request = request
        instance.session = session
      end

      it "creates a new PaulieNote record" do
        expect { instance.paulie_note(target) }.to change(PaulieNote, :count).by(1)
      end

      it "changes :paulie_notes_count for target" do
        expect { instance.paulie_note(target) }.to change(target, :paulie_notes_count).by(1)
      end
    end

    context "when string is passed" do
      let(:request) do
        double(
          headers: {
            "HTTP_SEC_CH_UA" => "Chrome",
            "HTTP_SEC_CH_UA_PLATFORM" => "Linux",
            "HTTP_SEC_CH_UA_MOBILE" => "?0"
          },
          env: { warden: nil },
          referrer: "referrer.com",
          remote_ip: "192.168.1.150",
          user_agent: "Mozilla/5.0 (X11; Linux x86_64)",
          accept_language: "uk-UA,uk;q=0.9,en-US;q=0.8"
        )
      end

      let(:session) { double(id: nil) }

      before do
        instance.request = request
        instance.session = session
      end

      it "creates note with type PaulieStaticPage" do
        instance.paulie_note("landing")
        expect(PaulieNote.last.noteable_type).to eq("PaulieStaticPage")
      end

      it "creates note with id landing" do
        instance.paulie_note("landing")
        expect(PaulieNote.last.noteable_id).to eq("landing")
      end
    end
  end
end
