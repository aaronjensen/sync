module Sync
  class Partial
    attr_accessor :name, :resource, :channel, :context

    def self.all(model, context)
      resource = Resource.new(model)

      Dir["app/views/sync/#{resource.plural_name}/**/_*.*"].map do |partial|
        partial_name = File.basename(partial)
        Partial.new(partial_name[1...partial_name.index('.')], resource.model, nil, context)
      end
    end


    def initialize(name, resource, channel, context)
      self.name = name
      self.resource = Resource.new(resource)
      self.channel = channel
      self.context = context
    end

    def render_to_string
      context.render_to_string(partial: path, locals: locals, formats: [:html])
    end

    def render
      context.render(partial: path, locals: locals, formats: [:html])
    end

    def cache_key(key)
      key
    end

    def template
      @template ||= context.find_template(path)
    end

    def sync(action)
      message(action).publish
    end

    def message(action)
      Sync.client.build_message channel_for_action(action), html: render_to_string
    end

    def channel_prefix
      @channel_prefix ||= Channel.new("#{polymorphic_path}-_#{name}").to_s
    end

    def channel_for_action(action)
      "#{channel_prefix}-#{action}"
    end

    def selector_start
      "#{channel_prefix}-start"
    end

    def selector_end
      "#{channel_prefix}-end"
    end


    private

    def path
      "sync/#{resource.plural_name}/#{name}"
    end

    def locals
      locals_hash = {}
      locals_hash[resource.name.to_sym] = resource.model

      locals_hash
    end

    def polymorphic_path
      if channel
        "/#{resource.plural_name}/#{channel}"
      else
        resource.polymorphic_path
      end
    end
  end
end
