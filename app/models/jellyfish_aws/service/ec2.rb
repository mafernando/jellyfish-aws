module JellyfishAws
  module Service
    class Ec2 < ::Service::Compute
      def actions
        actions = super.merge :terminate

        # determine if action is available

        actions
      end

      def provision

        server = nil

        handle_errors do


          # RHEL 7.1 - ami-12663b7a
          details = {
            image_id: self.product.answers.find { |x| x.name == 'image_id' }.value,
            flavor_id: 't2.micro',
            key_name: 'rhel-client',
            security_group_ids: ['sg-efb76e89']
          }

          binding.pry

          #   details['vpc_id'] = nil if details['vpc_id'].blank?
          #   details['subnet_id'] = nil if details['subnet_id'].blank?
          #   details['security_group_ids'] = nil if details['security_group_ids'].blank?
          #   server = connection.servers.create(details).tap { |s| s.wait_for { ready? } }

        end

        # POPULATE PAYLOAD RESPONSE TEMPLATE
        # payload_response = payload_response_template
        # payload_response[:raw] = JSON.parse(server.to_json)

        # INCLUDE IPADDRESS IF PRESENT
        # payload_response[:defaults][:ip_address] = server.public_ip_address unless server.public_ip_address.nil?
        #
        # @order_item.provision_status = :ok
        # @order_item.payload_response = payload_response

        # =begin
        #   create key_pair name: service.uuid
        #   create security group (one per project) name: project-{id}
        #   create vpc (one per project) name: project-{id}
        # =end
      end

      def start

      end

      def stop

      end

      def terminate

      end

      private

      def handle_errors
        yield
      rescue Excon::Errors::BadRequest, Excon::Errors::Forbidden => e
        raise e, 'Bad request. Check for valid credentials and proper permissions.', e.backtrace
      end

      def client
        @client ||= begin
          credentials = {
            provider: 'AWS',
            aws_access_key_id: self.provider.settings[:access_id],
            aws_secret_access_key: self.provider.settings[:secret_key],
            region: self.provider.settings[:region]
          }
          Fog::Compute.new credentials
        end
      end
    end
  end
end
