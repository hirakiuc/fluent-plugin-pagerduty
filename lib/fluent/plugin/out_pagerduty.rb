require 'fluent/plugin/output'

module Fluent::Plugin
  class PagerdutyOutput < Output
    Fluent::Plugin.register_output('pagerduty', self)

    config_param :service_key, :string, default: nil
    config_param :event_type,  :string, default: 'trigger'
    config_param :description, :string, default: nil

    def initialize
      require_relative './pagerduty_client.rb'
      super
    end

    def configure(conf)
      super

      if @service_key.nil?
        log.warn 'pagerduty: service_key required.'
      end
    end

    # method for non-buffered output mode
    def process(tag, es)
      es.each do |time, record|
        begin
          client.trigger(record)
        rescue => e
          # Do not throw error in non-buffered output mode.
        end
      end
    end

    # method for sync buffered output mode
    def write(chunk)
      log.debug 'process event to send pagerduty', chunk_id: dump_unique_id_hex(chunk.unique_id)

      chunk.each do |time, record|
        client.trigger(record)
      end
    end

    private

    def client
      return @client if @client

      defaults = {
        service_key: @service_key,
        event_type: @event_type
      }
      defaults[:description] = @description if @description

      @client = PagerdutyClient.new(defaults, log)
    end
  end
end
