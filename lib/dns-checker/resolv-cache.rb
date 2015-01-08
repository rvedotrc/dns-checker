module DNSChecker

  class ResolvCache

    attr_accessor :dir

    def initialize(dir)
      @dir = dir
    end

    def get_answer(nameservers, zone, type)

      nameservers.each do |ns|
        if answer = read_cache(ns, zone, type)
          puts "(cached)"
          return answer
        end
      end

      nameservers.shuffle.each do |ns|
        if answer = get_answer_lookup(ns, zone, type)
          write_cache(ns, zone, type, answer)
          puts "(fetched)"
          return answer
        end
      end

      raise "Didn't get an answer from any nameserver"

    end

    private

    def get_answer_lookup(ns, zone, type)
      answer = nil
      Resolv::DNS.new(:nameserver => [ns]).fetch_resource(zone, type) {|*args| answer = args}
      answer
    end

    def read_cache(ns, zone, type, now = nil)
      data = begin
        IO.read(cache_file(ns, zone, type))
      rescue Errno::ENOENT
        return nil
      end
      time, answer = Marshal.restore data

      # TODO check TTLs; return nil if expired
      # now ||= Time.now

      answer
    end

    def write_cache(ns, zone, type, answer, now = nil)
      now ||= Time.now
      data = Marshal.dump([ now, answer ])
      # TODO tmp + rename
      IO.write(cache_file(ns, zone, type), data)
    end

    def cache_file(ns, zone, type)
      "#{@dir}/#{ns}-#{zone.to_s}-#{type.name}"
    end

  end

end
