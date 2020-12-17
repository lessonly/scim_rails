module CallbackHelper
  class CallbackCounter
    attr_reader :before_called, :after_called
    attr_accessor :before, :after

    def initialize
      @before_called = 0
      @after_called = 0

      @before = lambda do
        @before_called += 1
      end

      @after = lambda do
        @after_called += 1
      end
    end
  end
end
