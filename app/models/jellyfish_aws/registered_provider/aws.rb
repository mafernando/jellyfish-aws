module JellyfishAws
  module RegisteredProvider
    class Aws < ::RegisteredProvider
      def self.load_registered_providers
        return unless super

        transaction do
          [
            set('AWS', '1072ddc9-e04f-4d43-929b-8866ce7e6d3a')
          ].each { |s| create! s.merge!(type: 'JellyfishAws::RegisteredProvider::Aws') }
        end
      end

      def provider_class
        'JellyfishAws::Provider::Aws'.constantize
      end

      def description
        'Amazon Web Services'
      end

      def tags
        ['aws']
      end

      def questions
        [
          { name: :access_id, value_type: :string, field: :text, label: 'Access ID', required: true },
          { name: :secret_key, value_type: :password, field: :password, label: 'Secret Key', required: :if_new },
          { name: :region, value_type: :string, field: :aws_regions, required: true }
        ]
      end
    end
  end
end
