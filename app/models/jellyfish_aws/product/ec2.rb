module JellyfishAws
  module Product
    class Ec2 < ::Product
      def order_questions
        [
        ]
      end

      def service_class
        'JellyfishAws::Service::Ec2'.constantize
      end

      private

      def init
        super
        self.img = 'products/aws_ec2.png'
      end
    end
  end
end
