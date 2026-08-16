# Starts an in-process background thread that drains the download queue every
# 10 minutes. The app runs as a single puma process, so this thread is the only
# downloader and sequential execution guarantees one download at a time.
class Scheduler
  INTERVAL = 10.minutes

  @thread = nil

  def self.start
    return if @thread&.alive?

    @thread = Thread.new do
      loop do
        Downstream.process_one
      rescue StandardError => e
        App.logger.error("scheduler: #{e.full_message}")
      ensure
        sleep INTERVAL
      end
    end
    @thread.name = 'chalaflix-scheduler'
  end
end
