module DNSChecker

  class ResolvCacheStore

    attr_accessor :dir

    def initialize(dir)
      @dir = dir
    end

    def get(key)
      data = begin
        IO.read(cache_file(key))
      rescue Errno::ENOENT
        return nil
      end
      Marshal.restore data
    end

    def put(key, value)
      data = Marshal.dump(value)
      # TODO tmp + rename
      IO.write(cache_file(key), data)
    end

    private

    def cache_file(key)
      # FIXME for now assume key is stringy, short, and contains no slashes or
      # nuls (i.e. can be used as part of filename)
      "#{@dir}/#{key}"
    end

  end

end
