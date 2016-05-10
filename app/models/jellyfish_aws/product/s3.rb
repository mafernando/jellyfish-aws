module JellyfishAws
  module Product
    class S3 < ::Product
      def order_questions
        [
        ]
      end

      def service_class
        'JellyfishAws::Service::S3'.constantize
      end

      private

      def init
        super
        self.img = 'products/aws_s3.png'
      end
    end
  end
end
