# module CarrierWave
#   module Storage
    class TuVieja < CarrierWave::Storage::Abstract
      def initialize(filepath)
        @delegate = CarrierWave::Storage::File.new(filepath)
      end

      def store!(file)
        begin
          raise file
        rescue => exception
          puts exception.backtrace
          @delegate.store! file
        end
      end

      def retrieve!(identifier)
        begin
          raise identifier
        rescue => exception
          puts exception.backtrace
          @delegate.retrieve! identifier
        end
      end
    end
#   end
# end
