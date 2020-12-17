module CallbackHelper
  class CallbackCounter
    attr_reader :count
    attr_accessor :before, :after

    def initialize
      @count = 0

      @before = lambda do
        @count += 1
      end

      @after = lambda do
        @count += 2
      end
    end
  end
end
