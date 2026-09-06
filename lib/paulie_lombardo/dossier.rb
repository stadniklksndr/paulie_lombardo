# frozen_string_literal: true

module PaulieLombardo
  # Build paulie_note attributes
  class Dossier
    attr_reader :data, :user_id, :interval, :target

    def initialize(controller, target, scope = nil)
      @request = controller.request
      @session = controller.session
      @user_id = user_id_from_warden
      @target = identify_subject(target)
      @interval = configured_interval(scope)

      build
    end

    def request_hash
      data[:request_hash]
    end

    def session_hash
      data[:session_hash]
    end

    def request_profile
      base_profile(request_hash: request_hash, session_hash: nil)
    end

    def session_profile
      base_profile(session_hash: session_hash)
    end

    def user_profile
      base_profile(user_id: user_id)
    end

    UUID_NAMESPACE = "9cac5761-c7b1-4c75-be24-1d4db88ac468"
    private_constant :UUID_NAMESPACE

    private

    attr_reader :request

    def build
      @data = {
        session_hash: generate_uuid(@session.id),
        request_hash: generate_uuid(raw_string),
        referrer: request.referrer
      }

      @data[:user_id] = user_id if user_id.present?
    end

    def generate_uuid(value)
      return if value.blank?

      Digest::UUID.uuid_v5(UUID_NAMESPACE, value.to_s)
    end

    def raw_string
      ["request_hash",
       request.user_agent,
       request.accept_language,
       mask_ip,
       http_sec_ch_ua,
       http_sec_ch_ua_platform,
       http_sec_ch_ua_mobile].compact.join("/")
    end

    def mask_ip
      addr = IPAddr.new(request.remote_ip)

      if addr.ipv4?
        addr.mask(24).to_s
      else
        addr.mask(48).to_s
      end
    end

    def http_sec_ch_ua
      request.headers["HTTP_SEC_CH_UA"]
    end

    def http_sec_ch_ua_platform
      request.headers["HTTP_SEC_CH_UA_PLATFORM"]
    end

    def http_sec_ch_ua_mobile
      request.headers["HTTP_SEC_CH_UA_MOBILE"]
    end

    def user_id_from_warden
      warden = request.env["warden"]
      return nil unless warden

      warden.user(:user)&.id
    end

    def configured_interval(scope)
      return scope if @target.is_a?(PaulieStaticPage)
      return unless @target.respond_to?(:paulie_notes_options)

      @target.paulie_notes_options[:interval]
    end

    def identify_subject(target)
      target.is_a?(ActiveRecord::Base) ? target : PaulieStaticPage.new(target)
    end

    def base_profile(attributes)
      attributes[:noteable_type] = @target.class.polymorphic_name
      attributes[:noteable_id] = @target.id.to_s
      attributes[:viewed_on] = Time.current.utc.to_date if interval == :daily
      attributes
    end
  end
end
