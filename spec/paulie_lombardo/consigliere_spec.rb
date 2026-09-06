# frozen_string_literal: true

RSpec.describe PaulieLombardo::Consigliere do
  def headers
    {
      "HTTP_SEC_CH_UA" => "HTTP_SEC_CH_UA",
      "HTTP_SEC_CH_UA_PLATFORM" => "HTTP_SEC_CH_UA_PLATFORM",
      "HTTP_SEC_CH_UA_MOBILE" => "HTTP_SEC_CH_UA_MOBILE"
    }
  end

  def request
    double(
      headers: headers,
      referrer: "referrer",
      remote_ip: "127.0.0.1",
      env: { "warden" => warden },
      user_agent: "user_agent",
      accept_language: "accept_language"
    )
  end

  def controller
    double(request: request, session: session)
  end

  let(:scope) { nil }
  let(:target) { create(:post) }
  let(:dossier) { PaulieLombardo::Dossier.new(controller, target, scope) }
  let(:consigliere) { described_class.new(dossier) }

  describe "#approve? interval: nil" do
    context "when session_hash is blank and paulie_note with request_hash is not saved yet" do
      let(:warden) { nil }
      let(:session) { double(id: nil) }

      it "checks session_hash is nil" do
        expect(dossier.session_hash).to be_nil
      end

      it "checks existence via request_profile" do
        allow(PaulieNote).to receive(:where).and_call_original
        consigliere.approve?

        expect(PaulieNote).to have_received(:where).with(dossier.request_profile)
      end

      it "checks existence via request_profile and calls none?" do
        relation = PaulieNote.where(dossier.request_profile)
        allow(PaulieNote).to receive(:where).with(dossier.request_profile) { relation }
        allow(relation).to receive(:none?).and_call_original

        consigliere.approve?

        expect(relation).to have_received(:none?)
      end

      it "checks paulie_notes count eq 0" do
        expect(PaulieNote.count).to be_zero
      end

      it "returns TRUE" do
        expect(consigliere.approve?).to be(true)
      end
    end

    context "when session_hash is blank and paulie_note alredy created with passed request_hash" do
      let(:warden) { nil }
      let(:session) { double(id: nil) }

      before do
        create(:paulie_note, request_hash: dossier.request_hash, noteable: target, session_hash: nil)
      end

      it "checks session_hash is nil" do
        expect(dossier.session_hash).to be_nil
      end

      it "checks paulie_note request_hash the same" do
        expect(PaulieNote.last.request_hash).to eq(dossier.request_hash)
      end

      it "checks paulie_notes count eq 1" do
        expect(PaulieNote.count).to eq(1)
      end

      it "checks existence via request_hash" do
        allow(PaulieNote).to receive(:where).and_call_original
        consigliere.approve?

        expect(PaulieNote).to have_received(:where).with(dossier.request_profile)
      end

      it "checks existence via request_hash and calls none?" do
        relation = PaulieNote.where(dossier.request_profile)
        allow(PaulieNote).to receive(:where).with(dossier.request_profile) { relation }
        allow(relation).to receive(:none?).and_call_original

        consigliere.approve?

        expect(relation).to have_received(:none?)
      end

      it "returns FALSE" do
        expect(consigliere.approve?).to be(false)
      end
    end

    context "when session_hash is blank and paulie_note was created but with other request_hash" do
      let(:warden) { nil }
      let(:session) { double(id: nil) }

      before do
        create(:paulie_note, request_hash: "other-request-hash", noteable: target, session_hash: nil)
      end

      it "checks session_hash is nil" do
        expect(dossier.session_hash).to be_nil
      end

      it "checks paulie_note request_hash is not the same" do
        expect(PaulieNote.last.request_hash).not_to eq(dossier.request_hash)
      end

      it "checks paulie_notes count eq 1" do
        expect(PaulieNote.count).to eq(1)
      end

      it "returns TRUE" do
        expect(consigliere.approve?).to be(true)
      end
    end

    # When a session is provided for the first time, the visitor already has a record with a request_hash.
    # In this case, search for an existing request_hash with a nil session_hash.
    # If a record is found, update it with the current session_hash.
    context "when session_hash available but not saved yet" do
      let(:warden) { nil }
      let(:session) { double(id: "session_id") }

      before do
        create(:paulie_note, request_hash: dossier.request_hash, noteable: target, session_hash: nil)
      end

      it "finds paulie_note by visitor request_hash and set session_hash" do
        consigliere.approve?

        expect(PaulieNote.last.session_hash).to eq(dossier.session_hash)
      end

      it "checks session_hash is not nil" do
        consigliere.approve?

        expect(PaulieNote.last.session_hash).not_to be_nil
      end

      it "checks paulie_notes count eq 1" do
        consigliere.approve?
        expect(PaulieNote.count).to eq(1)
      end

      it "returns FALSE" do
        expect(consigliere.approve?).to be(false)
      end
    end

    # When a session is provided for the first time but no record is found by request_hash,
    # it means two visitors share the same request_hash and the first one with a session already claimed it.
    # A new record will be created for the second visitor with both request_hash and session_hash set.
    context "when session_hash available and two users have the same request_hash" do
      let(:warden) { nil }
      let(:session) { double(id: "session_id") }

      before do
        create(:paulie_note, request_hash: dossier.request_hash, noteable: target, session_hash: "other_user_session")
      end

      it "checks paulie_note has the same request_hash" do
        expect(PaulieNote.last.request_hash).to eq(dossier.request_hash)
      end

      it "checks paulie_note has session_hash" do
        expect(PaulieNote.last.session_hash).to be_present
      end

      it "checks paulie_notes count eq 1" do
        consigliere.approve?
        expect(PaulieNote.count).to eq(1)
      end

      it "does not find record by request_hash and not set session_hash because it is taken by another user session" do
        consigliere.approve?
        expect(PaulieNote.last.session_hash).not_to eq(dossier.session_hash)
      end

      it "checks that new paulie_note data includes session_hash" do
        expect(dossier.data[:session_hash]).to be_present
      end

      it "returns TRUE" do
        expect(consigliere.approve?).to be(true)
      end
    end

    context "when session record exists, find it instead of creating a new one" do
      let(:warden) { nil }
      let(:session) { double(id: "session_id") }

      before do
        create(:paulie_note, request_hash: dossier.request_hash, noteable: target, session_hash: dossier.session_hash)
      end

      it "returns FALSE" do
        expect(consigliere.approve?).to be(false)
      end
    end

    context "when user is logged in and paulie_note record not yet created" do
      let(:session) { double(id: "session_id") }
      let(:warden) { double(user: double(id: 12)) }

      it "checks user present" do
        consigliere.approve?
        expect(dossier.user_id).to be_present
      end

      it "checks session_hash present" do
        consigliere.approve?
        expect(dossier.session_hash).to be_present
      end

      it "checks request_hash present" do
        consigliere.approve?
        expect(dossier.request_hash).to be_present
      end

      it "checks paulie_notes count eq 0" do
        consigliere.approve?
        expect(PaulieNote.count).to be_zero
      end

      it "checks existence via user_profile" do
        allow(PaulieNote).to receive(:where).and_call_original
        consigliere.approve?

        expect(PaulieNote).to have_received(:where).with(dossier.user_profile)
      end

      it "checks existence via user_profile and calls none?" do
        relation = PaulieNote.where(dossier.user_profile)
        allow(PaulieNote).to receive(:where).with(dossier.user_profile) { relation }
        allow(relation).to receive(:none?).and_call_original

        consigliere.approve?

        expect(relation).to have_received(:none?)
      end

      it "returns TRUE" do
        expect(consigliere.approve?).to be(true)
      end
    end

    context "when user is logged in and paulie_note record exist" do
      let(:user) { create(:user) }
      let(:session) { double(id: "session_id") }
      let(:warden) { double(user: user) }

      before do
        create(
          :paulie_note,
          noteable: target,
          user_id: user.id,
          request_hash: dossier.request_hash,
          session_hash: dossier.session_hash
        )
      end

      it "checks user present" do
        consigliere.approve?
        expect(dossier.user_id).to eq(user.id)
      end

      it "checks session_hash present" do
        consigliere.approve?
        expect(dossier.session_hash).to be_present
      end

      it "checks request_hash present" do
        consigliere.approve?
        expect(dossier.request_hash).to be_present
      end

      it "checks paulie_notes count eq 1" do
        consigliere.approve?
        expect(PaulieNote.count).to eq(1)
      end

      it "checks posts count eq 1" do
        consigliere.approve?
        expect(Post.count).to eq(1)
      end

      it "checks users count eq 1" do
        consigliere.approve?
        expect(User.count).to eq(1)
      end

      it "returns FALSE" do
        expect(consigliere.approve?).to be(false)
      end
    end
  end

  describe "#approve? interval: daily" do
    let(:target) { create(:question) }

    context "when session_hash is blank and paulie_note with request_hash is not saved yet" do
      let(:warden) { nil }
      let(:session) { double(id: nil) }

      let(:data) do
        {
          request_hash: dossier.request_hash,
          noteable_type: "Question",
          noteable_id: target.id.to_s,
          session_hash: nil,
          viewed_on: Time.current.utc.to_date
        }
      end

      it "includes :viewed_on column in query" do
        allow(Time).to receive(:current).and_return(Time.current)
        allow(PaulieNote).to receive(:where).and_call_original

        consigliere.approve?
        expect(PaulieNote).to have_received(:where).with(data)
      end

      it "returns TRUE" do
        expect(consigliere.approve?).to be(true)
      end
    end

    context "when session_hash is blank and paulie_note alredy created with passed request_hash" do
      let(:warden) { nil }
      let(:session) { double(id: nil) }

      before { allow(Time).to receive(:current).and_return(Time.current) }

      it "returns FALSE (is not approved when visits occur on the same day)" do
        create(:paulie_note, request_hash: dossier.request_hash, noteable: target, session_hash: nil)
        expect(consigliere.approve?).to be(false)
      end

      it "returns TRUE (is approved when visits occur on the next day)" do
        create(:paulie_note,
               request_hash: dossier.request_hash,
               noteable: target, session_hash: nil, viewed_on: Time.current.utc.to_date - 1.day)

        expect(consigliere.approve?).to be(true)
      end
    end

    # When a session is provided for the first time, the visitor already has a record with a request_hash.
    # In this case, search for an existing request_hash with a nil session_hash.
    # If a record is found, update it with the current session_hash.
    context "when session_hash available but not saved yet" do
      let(:warden) { nil }
      let(:session) { double(id: "session_id") }

      let(:data) do
        {
          session_hash: dossier.session_hash,
          noteable_type: "Question",
          noteable_id: target.id.to_s,
          viewed_on: Time.current.utc.to_date
        }
      end

      let!(:note) { create(:paulie_note, dossier.request_profile) }

      before { allow(Time).to receive(:current).and_return(Time.current) }

      it "includes :viewed_on column in query" do
        allow(PaulieNote).to receive(:where).and_call_original
        consigliere.approve?
        expect(PaulieNote).to have_received(:where).with(data)
      end

      it "checks session_hash is nil" do
        expect(note.session_hash).to be_nil
      end

      it "set session_hash to existing paulie_note with request_hash" do
        consigliere.approve?
        expect(note.reload.session_hash).to eq(dossier.session_hash)
      end

      it "verifies noteable has an interval" do
        expect(note.noteable.paulie_notes_options[:interval]).to eq(:daily)
      end

      it "verifies dossier has an interval" do
        expect(dossier.interval).to eq(:daily)
      end

      it "returns FALSE" do
        expect(consigliere.approve?).to be(false)
      end
    end

    context "when session_hash available and already saved" do
      let(:warden) { nil }
      let(:session) { double(id: "session_id") }
      let!(:note) { create(:paulie_note, dossier.session_profile.merge(request_hash: dossier.request_hash)) }

      before { allow(Time).to receive(:current).and_return(Time.current) }

      it "verifies noteable has an interval" do
        expect(note.noteable.paulie_notes_options[:interval]).to eq(:daily)
      end

      it "verifies dossier has an interval" do
        expect(dossier.interval).to eq(:daily)
      end

      it "returns FALSE (finds created paulie_note by session when visits occur on the same day)" do
        expect(consigliere.approve?).to be(false)
      end

      it "returns TRUE (cannot find created paulie_note by session when visits occur on the next day)" do
        note.update_attribute(:viewed_on, Time.current.utc.to_date - 1.day)
        expect(consigliere.approve?).to be(true)
      end
    end

    context "when session_hash available on the next day" do
      let(:warden) { nil }
      let(:session) { double(id: "session_id") }

      before { allow(Time).to receive(:current).and_return(Time.current) }

      it "does not set session_hash for existing note with request_hash" do
        note = create(:paulie_note, dossier.request_profile.merge(viewed_on: Time.current.utc.to_date - 1.day))
        consigliere.approve?
        expect(note.reload.session_hash).to be_nil
      end

      it "returns TRUE (cannot find created paulie_note by request_hash when visits occur on the next day)" do
        create(:paulie_note, dossier.request_profile.merge(viewed_on: Time.current.utc.to_date - 1.day))
        expect(consigliere.approve?).to be(true)
      end
    end

    context "when user is logged in and paulie_note record not yet created" do
      let(:user) { create(:user) }
      let(:session) { double(id: "session_id") }
      let(:warden) { double(user: user) }

      let(:data) do
        {
          user_id: user.id,
          noteable_type: "Question",
          noteable_id: target.id.to_s,
          viewed_on: Time.current.utc.to_date
        }
      end

      it "checks user present" do
        expect(dossier.user_id).to eq(user.id)
      end

      it "includes :viewed_on column in query" do
        allow(Time).to receive(:current).and_return(Time.current)
        allow(PaulieNote).to receive(:where).and_call_original

        consigliere.approve?
        expect(PaulieNote).to have_received(:where).with(data)
      end

      it "returns TRUE" do
        expect(consigliere.approve?).to be(true)
      end
    end

    context "when user is logged in and paulie_note record exist" do
      let(:user) { create(:user) }
      let(:session) { double(id: "session_id") }
      let(:warden) { double(user: user) }

      before { allow(Time).to receive(:current).and_return(Time.current) }

      it "returns FALSE (when visits occur on the same day)" do
        create(:paulie_note, dossier.user_profile)
        expect(consigliere.approve?).to be(false)
      end

      it "returns TRUE (when visits occur on the next day)" do
        create(:paulie_note, dossier.user_profile.merge(viewed_on: Time.current.utc.to_date - 1.day))
        expect(consigliere.approve?).to be(true)
      end
    end
  end

  describe "#approve? for static page interval: nil" do
    let(:target) { "landing" }

    context "when session_hash is blank and paulie_note with request_hash is not saved yet" do
      let(:warden) { nil }
      let(:session) { double(id: nil) }

      let(:data) do
        {
          request_hash: dossier.request_hash,
          noteable_type: "PaulieStaticPage",
          noteable_id: "landing",
          session_hash: nil
        }
      end

      it "includes data in query" do
        allow(PaulieNote).to receive(:where).and_call_original

        consigliere.approve?
        expect(PaulieNote).to have_received(:where).with(data)
      end

      it "returns TRUE" do
        expect(consigliere.approve?).to be(true)
      end
    end

    context "when session_hash is blank and paulie_note alredy created with passed request_hash" do
      let(:warden) { nil }
      let(:session) { double(id: nil) }
      let(:target) { "landing" }

      it "returns FALSE" do
        create(
          :paulie_note,
          request_hash: dossier.request_hash,
          noteable_type: "PaulieStaticPage", noteable_id: "landing", session_hash: nil
        )
        expect(consigliere.approve?).to be(false)
      end
    end

    context "when session_hash available but not saved yet" do
      let(:warden) { nil }
      let(:target) { "landing" }
      let(:session) { double(id: "session_id") }

      let(:data) do
        {
          session_hash: dossier.session_hash,
          noteable_type: "PaulieStaticPage",
          noteable_id: target
        }
      end

      let!(:note) { create(:paulie_note, dossier.request_profile) }

      it "includes data in query" do
        allow(PaulieNote).to receive(:where).and_call_original
        consigliere.approve?
        expect(PaulieNote).to have_received(:where).with(data)
      end

      it "checks session_hash is nil" do
        expect(note.session_hash).to be_nil
      end

      it "set session_hash to existing paulie_note with request_hash" do
        consigliere.approve?
        expect(note.reload.session_hash).to eq(dossier.session_hash)
      end

      it "returns FALSE" do
        expect(consigliere.approve?).to be(false)
      end
    end

    context "when session_hash available and already saved" do
      let(:warden) { nil }
      let(:target) { "landing" }
      let(:session) { double(id: "session_id") }

      it "does not create new note" do
        create(:paulie_note, dossier.session_profile.merge(request_hash: dossier.request_hash))
        consigliere.approve?
        expect(PaulieNote.count).to eq(1)
      end

      it "returns FALSE (finds created paulie_note by session)" do
        create(:paulie_note, dossier.session_profile.merge(request_hash: dossier.request_hash))
        expect(consigliere.approve?).to be(false)
      end
    end

    context "when user is logged in and paulie_note record not yet created" do
      let(:user) { create(:user) }
      let(:target) { "landing" }
      let(:session) { double(id: "session_id") }
      let(:warden) { double(user: user) }

      let(:data) do
        {
          user_id: user.id,
          noteable_type: "PaulieStaticPage",
          noteable_id: target
        }
      end

      it "checks user present" do
        expect(dossier.user_id).to eq(user.id)
      end

      it "includes data in query" do
        allow(PaulieNote).to receive(:where).and_call_original

        consigliere.approve?
        expect(PaulieNote).to have_received(:where).with(data)
      end

      it "returns TRUE" do
        expect(consigliere.approve?).to be(true)
      end
    end

    context "when user is logged in and paulie_note record exist" do
      let(:user) { create(:user) }
      let(:target) { "landing" }
      let(:session) { double(id: "session_id") }
      let(:warden) { double(user: user) }

      it "returns FALSE (when visits occur on the same day)" do
        create(:paulie_note, dossier.user_profile)
        expect(consigliere.approve?).to be(false)
      end
    end
  end

  describe "#approve? for static page interval: daily" do
    let(:scope) { :daily }
    let(:target) { "landing" }

    context "when session_hash is blank and paulie_note with request_hash is not saved yet" do
      let(:warden) { nil }
      let(:session) { double(id: nil) }

      let(:data) do
        {
          request_hash: dossier.request_hash,
          noteable_type: "PaulieStaticPage",
          noteable_id: target,
          session_hash: nil,
          viewed_on: Time.current.utc.to_date
        }
      end

      it "includes :viewed_on column in query" do
        allow(Time).to receive(:current).and_return(Time.current)
        allow(PaulieNote).to receive(:where).and_call_original

        consigliere.approve?
        expect(PaulieNote).to have_received(:where).with(data)
      end

      it "returns TRUE" do
        expect(consigliere.approve?).to be(true)
      end
    end

    context "when session_hash is blank and paulie_note alredy created with passed request_hash" do
      let(:warden) { nil }
      let(:session) { double(id: nil) }

      before { allow(Time).to receive(:current).and_return(Time.current) }

      it "returns FALSE (is not approved when visits occur on the same day)" do
        create(:paulie_note,
               request_hash: dossier.request_hash,
               noteable_type: "PaulieStaticPage", noteable_id: target, session_hash: nil)

        expect(consigliere.approve?).to be(false)
      end

      it "returns TRUE (is approved when visits occur on the next day)" do
        create(:paulie_note,
               request_hash: dossier.request_hash, noteable_type: "PaulieStaticPage",
               noteable_id: target, session_hash: nil, viewed_on: Time.current.utc.to_date - 1.day)

        expect(consigliere.approve?).to be(true)
      end
    end

    context "when session_hash available but not saved yet" do
      let(:warden) { nil }
      let(:session) { double(id: "session_id") }

      let(:data) do
        {
          session_hash: dossier.session_hash,
          noteable_type: "PaulieStaticPage",
          noteable_id: target,
          viewed_on: Time.current.utc.to_date
        }
      end

      let!(:note) { create(:paulie_note, dossier.request_profile) }

      before { allow(Time).to receive(:current).and_return(Time.current) }

      it "includes :viewed_on column in query" do
        allow(PaulieNote).to receive(:where).and_call_original
        consigliere.approve?
        expect(PaulieNote).to have_received(:where).with(data)
      end

      it "checks session_hash is nil" do
        expect(note.session_hash).to be_nil
      end

      it "set session_hash to existing paulie_note with request_hash" do
        consigliere.approve?
        expect(note.reload.session_hash).to eq(dossier.session_hash)
      end

      it "verifies dossier has an interval" do
        expect(dossier.interval).to eq(:daily)
      end

      it "returns FALSE" do
        expect(consigliere.approve?).to be(false)
      end
    end

    context "when session_hash available and already saved" do
      let(:warden) { nil }
      let(:session) { double(id: "session_id") }
      let!(:note) { create(:paulie_note, dossier.session_profile.merge(request_hash: dossier.request_hash)) }

      before { allow(Time).to receive(:current).and_return(Time.current) }

      it "verifies dossier has an interval" do
        expect(dossier.interval).to eq(:daily)
      end

      it "returns FALSE (finds created paulie_note by session when visits occur on the same day)" do
        expect(consigliere.approve?).to be(false)
      end

      it "returns TRUE (cannot find created paulie_note by session when visits occur on the next day)" do
        note.update_attribute(:viewed_on, Time.current.utc.to_date - 1.day)
        expect(consigliere.approve?).to be(true)
      end
    end

    context "when session_hash available on the next day" do
      let(:warden) { nil }
      let(:session) { double(id: "session_id") }

      before { allow(Time).to receive(:current).and_return(Time.current) }

      it "does not set session_hash for existing note with request_hash" do
        note = create(:paulie_note,
                      request_hash: dossier.request_hash, noteable_type: "PaulieStaticPage",
                      noteable_id: target, session_hash: nil, viewed_on: Time.current.utc.to_date - 1.day)

        consigliere.approve?
        expect(note.reload.session_hash).to be_nil
      end

      it "returns TRUE (cannot find created paulie_note by request_hash when visits occur on the next day)" do
        create(:paulie_note,
               request_hash: dossier.request_hash, noteable_type: "PaulieStaticPage",
               noteable_id: target, session_hash: nil, viewed_on: Time.current.utc.to_date - 1.day)

        expect(consigliere.approve?).to be(true)
      end
    end

    context "when user is logged in and paulie_note record not yet created" do
      let(:user) { create(:user) }
      let(:session) { double(id: "session_id") }
      let(:warden) { double(user: user) }

      let(:data) do
        {
          user_id: user.id,
          noteable_type: "PaulieStaticPage",
          noteable_id: target,
          viewed_on: Time.current.utc.to_date
        }
      end

      it "checks user present" do
        expect(dossier.user_id).to eq(user.id)
      end

      it "includes :viewed_on column in query" do
        allow(Time).to receive(:current).and_return(Time.current)
        allow(PaulieNote).to receive(:where).and_call_original

        consigliere.approve?
        expect(PaulieNote).to have_received(:where).with(data)
      end

      it "returns TRUE" do
        expect(consigliere.approve?).to be(true)
      end
    end

    context "when user is logged in and paulie_note record exist" do
      let(:user) { create(:user) }
      let(:session) { double(id: "session_id") }
      let(:warden) { double(user: user) }

      before { allow(Time).to receive(:current).and_return(Time.current) }

      it "returns FALSE (when visits occur on the same day)" do
        create(:paulie_note, user_id: user.id, noteable_type: "PaulieStaticPage", noteable_id: target)
        expect(consigliere.approve?).to be(false)
      end

      it "returns TRUE (when visits occur on the next day)" do
        create(:paulie_note,
               user_id: user.id, noteable_type: "PaulieStaticPage",
               noteable_id: target, viewed_on: Time.current.utc.to_date - 1.day)

        expect(consigliere.approve?).to be(true)
      end
    end
  end
end
