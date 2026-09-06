# frozen_string_literal: true

module PaulieLombardo
  # Railtie integration to automatically load Controller and Model concerns
  # into Rails framework components upon initialization.
  class Railtie < ::Rails::Railtie
    initializer "paulie_lombardo.controller" do
      ActiveSupport.on_load(:action_controller) do
        include PaulieLombardo::Controller
      end
    end

    initializer "paulie_lombardo.active_record" do
      ActiveSupport.on_load(:active_record) do
        include PaulieLombardo::Model
      end
    end
  end
end
