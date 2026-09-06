# frozen_string_literal: true

RSpec.describe PaulieLombardo::Dossier do
  let(:request) do
    double(
      headers: headers,
      referrer: "referrer.com",
      remote_ip: ip,
      env: { "warden" => warden },
      user_agent: "Mozilla/5.0 (X11; Linux x86_64)",
      accept_language: "uk-UA,uk;q=0.9,en-US;q=0.8"
    )
  end

  let(:headers) do
    {
      "HTTP_SEC_CH_UA" => "Chrome",
      "HTTP_SEC_CH_UA_PLATFORM" => "Linux",
      "HTTP_SEC_CH_UA_MOBILE" => "?0"
    }
  end

  let(:target) { create(:post) }
  let(:ip) { "192.168.1.150" }
  let(:user) { create(:user) }
  let(:session) { double(id: "session_id") }
  let(:warden) { double(user: user) }
  let(:controller) { double(request: request, session: session) }
  let(:dossier) { described_class.new(controller, target) }

  describe ".initialize" do
    context "when build instance" do
      it "set @request variable" do
        expect(dossier.instance_variable_get(:@request)).to be_present
      end

      it "set @session variable" do
        expect(dossier.instance_variable_get(:@session)).to be_present
      end

      it "set @user_id variable" do
        expect(dossier.instance_variable_get(:@user_id)).to eq(user.id)
      end

      it "set @target variable" do
        expect(dossier.instance_variable_get(:@target)).to eq(target)
      end

      it "set @data variable" do
        expect(dossier.instance_variable_get(:@data)).to be_present
      end

      it "defines :request as a private method" do
        expect(dossier.private_methods).to include(:request)
      end

      it "defines UUID_NAMESPACE" do
        expect(described_class.const_get(:UUID_NAMESPACE)).to be_present
      end

      it "defines UUID_NAMESPACE as a private constant" do
        expect { described_class::UUID_NAMESPACE }.to raise_error(NameError, /private constant/)
      end

      it "defines :user_id method" do
        expect(dossier.user_id).to eq(user.id)
      end

      it "returns nil for interbal option" do
        expect(dossier.interval).to be_nil
      end
    end

    context "when build request_hash" do
      context "when IP is IPv4" do
        it "masks the last octet (24-bit mask)" do
          addr = IPAddr.new(request.remote_ip)
          allow(IPAddr).to receive(:new) { addr }
          allow(addr).to receive(:mask).with(24)
          described_class.new(controller, target)
          expect(addr).to have_received(:mask).with(24)
        end
      end

      context "when IP is IPv6" do
        let(:ip) { "2001:db8:abcd:0012:0000:0000:0000:0001" }

        it "masks using 48-bit prefix" do
          addr = IPAddr.new(request.remote_ip)
          allow(IPAddr).to receive(:new) { addr }
          allow(addr).to receive(:mask).with(48)
          described_class.new(controller, target)
          expect(addr).to have_received(:mask).with(48)
        end
      end

      it "uses user_agent" do
        described_class.new(controller, target)
        expect(request).to have_received(:user_agent)
      end

      it "uses accept_language" do
        described_class.new(controller, target)
        expect(request).to have_received(:accept_language)
      end

      it "uses HTTP_SEC_CH_UA header to build request_hash" do
        allow(request).to receive(:headers).and_return(headers)
        allow(headers).to receive(:[]).and_call_original

        described_class.new(controller, target)

        expect(headers).to have_received(:[]).with("HTTP_SEC_CH_UA")
      end

      it "uses HTTP_SEC_CH_UA_PLATFORM to build request_hash" do
        allow(request).to receive(:headers).and_return(headers)
        allow(headers).to receive(:[]).and_call_original

        described_class.new(controller, target)

        expect(headers).to have_received(:[]).with("HTTP_SEC_CH_UA_PLATFORM")
      end

      it "uses HTTP_SEC_CH_UA_MOBILE to build request_hash" do
        allow(request).to receive(:headers).and_return(headers)
        allow(headers).to receive(:[]).and_call_original

        described_class.new(controller, target)

        expect(headers).to have_received(:[]).with("HTTP_SEC_CH_UA_MOBILE")
      end

      it "uses IPAddr" do
        allow(IPAddr).to receive(:new).and_call_original
        described_class.new(controller, target)
        expect(IPAddr).to have_received(:new).with(ip)
      end
    end

    context "when build data" do
      it "uses referrer" do
        described_class.new(controller, target)
        expect(request).to have_received(:referrer)
      end

      it "uses Digest::UUID to build request and session hash" do
        allow(Digest::UUID).to receive(:uuid_v5)
        described_class.new(controller, target)
        expect(Digest::UUID).to have_received(:uuid_v5).twice
      end

      it "includes session_hash" do
        expect(dossier.data[:session_hash]).to be_present
      end

      it "includes request_hash" do
        expect(dossier.data[:request_hash]).to be_present
      end

      it "includes referrer" do
        expect(dossier.data[:referrer]).to be_present
      end

      it "includes user_id" do
        expect(dossier.data[:user_id]).to be_present
      end

      it "returns a hash with only the expected keys" do
        expect(dossier.data.keys).to contain_exactly(
          :request_hash, :session_hash, :referrer, :user_id
        )
      end

      context "without session" do
        let(:session) { double(id: nil) }

        it "uses Digest::UUID to build ONLY request_hash" do
          allow(Digest::UUID).to receive(:uuid_v5)
          described_class.new(controller, target)
          expect(Digest::UUID).to have_received(:uuid_v5)
        end
      end
    end

    context "when configured interval" do
      let(:target) { create(:question) }

      it "returns :daily option" do
        expect(dossier.interval).to eq(:daily)
      end
    end

    context "when gets user from warden" do
      let(:warden) { double }

      it "looks at :user scope" do
        allow(warden).to receive(:user) { double(id: 1) }
        described_class.new(controller, target)

        expect(warden).to have_received(:user).with(:user)
      end

      it "gets id of warden user" do
        warden_user = double(id: 1)
        allow(warden).to receive(:user) { warden_user }
        described_class.new(controller, target)

        expect(warden_user).to have_received(:id)
      end
    end

    context "when user is missing" do
      let(:user) { nil }

      it "returns a hash with only the expected keys" do
        expect(dossier.data.keys).to contain_exactly(
          :request_hash, :session_hash, :referrer
        )
      end
    end
  end

  describe "#request_hash" do
    it "returns the request hash from data" do
      expect(dossier.request_hash).to eq(dossier.data[:request_hash])
    end
  end

  describe "#session_hash" do
    it "returns the session hash from data" do
      expect(dossier.session_hash).to eq(dossier.data[:session_hash])
    end
  end

  describe "#request_profile" do
    context "without interval" do
      it "returns a hash with request_hash, noteable, and nil session_hash" do
        expect(dossier.request_profile).to include(
          request_hash: dossier.request_hash,
          noteable_type: target.class.polymorphic_name,
          noteable_id: target.id.to_s,
          session_hash: nil
        )
      end

      it "returns a hash with only the expected keys" do
        expect(dossier.request_profile.keys).to contain_exactly(
          :request_hash, :noteable_type, :noteable_id, :session_hash
        )
      end
    end

    context "with :daily interval" do
      let(:target) { create(:question) }

      before { allow(Time).to receive(:current).and_return(Time.current) }

      it "returns a hash with request_hash, noteable, viewed_on, and nil session_hash" do
        expect(dossier.request_profile).to include(
          request_hash: dossier.request_hash, noteable_type: target.class.polymorphic_name,
          noteable_id: target.id.to_s, session_hash: nil, viewed_on: Time.current.utc.to_date
        )
      end

      it "returns a hash with only the expected keys" do
        expect(dossier.request_profile.keys).to contain_exactly(
          :request_hash, :noteable_type, :noteable_id, :session_hash, :viewed_on
        )
      end
    end
  end

  describe "#session_profile" do
    context "without interval" do
      it "returns a hash with session_hash and noteable" do
        expect(dossier.session_profile).to include(
          session_hash: dossier.session_hash,
          noteable_type: target.class.polymorphic_name,
          noteable_id: target.id.to_s
        )
      end

      it "returns a hash with only the expected keys" do
        expect(dossier.session_profile.keys).to contain_exactly(:session_hash, :noteable_type, :noteable_id)
      end
    end

    context "with :daily interval" do
      let(:target) { create(:question) }

      before { allow(Time).to receive(:current).and_return(Time.current) }

      it "returns a hash with session_hash and noteable" do
        expect(dossier.session_profile).to include(
          session_hash: dossier.session_hash,
          noteable_type: target.class.polymorphic_name,
          noteable_id: target.id.to_s,
          viewed_on: Time.current.utc.to_date
        )
      end

      it "returns a hash with only the expected keys" do
        expect(dossier.session_profile.keys).to contain_exactly(:session_hash, :noteable_type, :noteable_id, :viewed_on)
      end
    end
  end

  describe "#user_profile" do
    context "without interval" do
      it "returns a hash with user_id and noteable" do
        expect(dossier.user_profile).to include(
          user_id: dossier.user_id,
          noteable_type: target.class.polymorphic_name,
          noteable_id: target.id.to_s
        )
      end

      it "returns a hash with only the expected keys" do
        expect(dossier.user_profile.keys).to contain_exactly(:user_id, :noteable_type, :noteable_id)
      end
    end

    context "with :daily interval" do
      let(:target) { create(:question) }

      before { allow(Time).to receive(:current).and_return(Time.current) }

      it "returns a hash with user_id and noteable" do
        expect(dossier.user_profile).to include(
          user_id: dossier.user_id,
          noteable_type: target.class.polymorphic_name,
          noteable_id: target.id.to_s,
          viewed_on: Time.current.utc.to_date
        )
      end

      it "returns a hash with only the expected keys" do
        expect(dossier.user_profile.keys).to contain_exactly(:user_id, :noteable_type, :noteable_id, :viewed_on)
      end
    end
  end
end
