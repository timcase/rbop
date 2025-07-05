# frozen_string_literal: true

module Rbop
  module Selector
    class << self
      def parse(**kwargs)
        validate_arguments!(kwargs)

        case kwargs.keys.first
        when :title
          { type: :title, value: kwargs[:title] }
        when :id
          { type: :id, value: kwargs[:id] }
        when :url
          parse_url(kwargs[:url])
        end
      end

      private

      def validate_arguments!(kwargs)
        if kwargs.empty?
          raise ArgumentError, "Must provide one of: title:, id:, or url:"
        end

        if kwargs.keys.length > 1
          raise ArgumentError, "Must provide exactly one of: title:, id:, or url:"
        end

        unless [ :title, :id, :url ].include?(kwargs.keys.first)
          raise ArgumentError, "Must provide one of: title:, id:, or url:"
        end
      end

      def parse_url(url)
        if url.start_with?("https://share.1password.com/")
          { type: :url_share, value: url }
        elsif url.include?("/open/i?")
          { type: :url_private, value: url }
        else
          raise ArgumentError, "URL must be a valid 1Password share URL or private link"
        end
      end
    end
  end
end
