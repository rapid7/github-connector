class BaseExecutor

  # A list of errors that occurred while running this synchronizer
  # @return [Array<StandardError>]
  attr_reader :errors

  # The number of threads to use when running.
  # @return [Fixnum]
  attr_accessor :thread_count

  # Runs the executor.
  #
  # @return [BaseExecutor] instance of the executor that ran the task
  def self.run!
    new.tap { |instance| instance.run! }
  end

  def initialize
    @thread_count = [5, ActiveRecord::Base.connection_pool.size - 1].min
    @semaphore = Mutex.new
    @errors = []
  end

  private

  # Obtains a lock, runs the block, and releases the lock when the block completes.
  #
  # @see `Mutex#synchronize`
  def synchronize(&block)
    @semaphore.synchronize(&block)
  end

  # Runs the given block for each object in parallel.  Up to
  # {#thread_count} threads are used to run the block.  This waits
  # for all threads to complete before returning.
  #
  # @param objs [Enumerable<Object>] an array of objects
  # @yieldparam obj [Object] a single object from the array of objects
  # @return [void]
  def thread_for_each(objs)
    ary = objs.to_a
    ary = ary.dup if ary === objs

    threads = []
    [ary.size, thread_count].min.times do
      threads << Thread.new do |thread|
        ActiveRecord::Base.connection_pool.with_connection do
          while (obj = synchronize { ary.shift })
            yield obj
          end
        end
      end
    end
    threads.each { |t| t.join }
  end
end
