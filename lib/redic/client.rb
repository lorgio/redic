require "redic/connection"
require "uri"

class Redic
  class Client
    def initialize(url)
      @uri = URI.parse(url)
      @connection = nil
      @semaphore = Mutex.new
    end

    def read
      @connection.read
    end

    def write(command)
      @connection.write(command)
    end

    def connect
      establish_connection unless connected?

      @semaphore.synchronize do
        yield
      end
    rescue Errno::ECONNRESET
      @connection = nil
      retry
    end

  private
    def establish_connection
      begin
        @connection = Redic::Connection.new(@uri)
      rescue StandardError => err
        raise err, "Can't connect to: %s" % @uri
      end

      authenticate
    end

    def authenticate
      if @uri.password
        @semaphore.synchronize do
          write [:auth, @uri.password]
          read
        end
      end
    end

    def connected?
      @connection && @connection.connected?
    end
  end
end
