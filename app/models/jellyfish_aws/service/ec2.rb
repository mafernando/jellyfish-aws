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
          # HARDCODED RHEL 7.1 - ami-12663b7a
          details = {
            image_id: self.product.answers.find { |x| x.name == 'image_id' }.value,
            flavor_id: 't2.micro',
            key_name: 'rhel-client',
            security_group_ids: ['sg-efb76e89']
          }

          # CREATE THE AWS SERVER AND WAIT FOR CALLBACK
          server = client.servers.create(details).tap { |s| s.wait_for { ready? } }

          # PERSIST SERVER PUBLIC IP
          persist_attributes(server.attributes) if defined? server.attributes

          # CONFIGURE FIREWALL RULES UNLESS NO PUBLIC IP EXISTS FOR SERVER     
          configure_firewall_rules unless service_outputs.where(name: 'public_ip_address').last.nil?

          # SUCCESS OR FAIL NOTIFICATION	          
          self.status = ::Service.defined_enums['status']['running']
          self.status_msg = 'running'
          self.save
        end
      end

      def start

      end

      def stop

      end

      def terminate

      end

      private

      def persist_attributes(attributes)
        output = ServiceOutput.new name: 'public_ip_address', value: attributes[:public_ip_address], value_type: ValueTypes::TYPES[:string]
        self.service_outputs << output
      end

      def configure_firewall_rules
        # GET AWS EC2 WEBSERVER PUBLIC IP ADDRESS
        aws_public_ip = service_outputs.where(name: 'public_ip_address').last.value

        # CREATE FIREWALL RULE TO ALLOW CLIENT TO ACCESS NEWLY CREATED INSTANCE
        odl_client.create_auto_rule aws_public_ip
      end

      def handle_errors
        yield
      rescue Excon::Errors::BadRequest, Excon::Errors::Forbidden => e
        raise e, 'Request failed, check for valid credentials and proper permissions.', e.backtrace
      end

      def odl_client
        @odl_client ||= odl_service.provider.odl_client odl_service
      end

      def odl_service
        @odl_service ||= JellyfishOdl::Service::Server.last
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
