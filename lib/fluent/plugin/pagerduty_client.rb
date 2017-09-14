require 'pagerduty'

class PagerdutyClient
  def initialize(defaults, logger)
    @defaults = defaults
    @logger = logger

    @pool = {}
  end

  def trigger(record)
    client = client_with_service_key(record['service_key'] || @defaults[:service_key])

    desc, options = format_record(record)
    client.trigger desc, options
  rescue => e
    @logger.error 'pagerduty: request failed.', error_class: e.class, error: e.message
    throw e
  end

  private

  def client_with_service_key(service_key)
    @pool[service_key] || @pool[service_key] = Pagerduty.new(service_key)
  end

  def format_record(record)
    description = record['description'] || record['message'] || @defaults[:description]
    options = { details: (record['details'] || record) }

    return description, options
  end
end
