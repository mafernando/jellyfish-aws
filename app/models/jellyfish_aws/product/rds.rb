module JellyfishAws
  module Product
    class RDS < ::Product
      def order_questions
        [
        ]
      end

      def service_class
        'JellyfishAws::Service::RDS'.constantize
      end

      private

      def init
        super
        self.img = 'products/aws_rds.png'
      end
    end
  end
end
