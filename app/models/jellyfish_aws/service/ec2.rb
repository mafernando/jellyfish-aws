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
        odl_client_class = Class.new do
          attr_accessor :odl_service
          attr_accessor :default_client_ip, :default_action
          attr_accessor :odl_controller_ip, :odl_controller_port, :odl_username, :odl_password
          def initialize
            @odl_service = JellyfishOdl::Service::Server.last
            @odl_controller_ip = odl_service.provider.answers.where(name: 'ip_address').last.value
            @odl_controller_port = odl_service.provider.answers.where(name: 'port').last.value
            @odl_username = @odl_service.provider.answers.where(name: 'username').last.value
            @odl_password = @odl_service.provider.answers.where(name: 'password').last.value
            # GET ODL CLIENT IP - STORED ON PRODUCT
            @default_client_ip = @odl_service.product.answers.where(name: 'product_placeholder').last.value
            # GET ODL DEFAULT RULE ACTION - STORED ON ORDER
            @default_action = @odl_service.answers.where(name: 'order_placeholder').last.value
          end
          def headers
            { 'Content-Type' => 'application/json', 'Accept' => 'application/json' }
          end
          def auth
            { username: @odl_username, password: @odl_password }
          end
          def rules_endpoint
            "http://#{@odl_controller_ip}:#{@odl_controller_port}/restconf/config/network-topology:network-topology/topology/topology-netconf/node/vRouter5600/yang-ext:mount/vyatta-security:security/vyatta-security-firewall:firewall/name/test"
          end
          def rule_endpoint(rule_num)
            rules_endpoint+"/rule/#{rule_num}"
          end
          def rules
            HTTParty.get(rules_endpoint, basic_auth: auth, headers: headers)
          end
          def next_rule_num
            current_max_tagnode = rules.first.second[0]['rule'].max_by { |i| i['tagnode'] }['tagnode'] + 1
            rule_buffer_threshold = 5.0
            next_num = Integer((current_max_tagnode/rule_buffer_threshold).ceil*rule_buffer_threshold)
            [Integer(rule_buffer_threshold), next_num].max
          end
          def create_auto_rule(remote_ip=@default_client_ip)
            create_rule(next_rule_num, @default_action, @default_client_ip, remote_ip)
          end
          def create_rule(rule_num=0, action, source_ip, dest_ip)
            body = { rule: { tagnode: rule_num, action: action, source: {address: source_ip}, destination: {address: dest_ip} } }.to_json
            HTTParty.post(rules_endpoint, basic_auth: auth, headers: headers, body: body) unless rule_num < 1
          end
          def delete_rule(rule_num=0)
            HTTParty.delete(rule_endpoint(rule_num), basic_auth: auth, headers: headers) unless rule_num < 1
          end
        end
        @odl_client ||= odl_client_class.new
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
