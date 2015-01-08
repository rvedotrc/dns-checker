module DNSChecker

  class ResolvCache

    attr_accessor :dir

    def initialize(dir)
      @dir = dir
    end

    def get_answer(nameservers, zone, type)

      nameservers.each do |ns|
        if retval = read_cache(ns, zone, type)
          puts "(cached)"
          return retval
        end
      end

      nameservers.shuffle.each do |ns|
        if retval = get_answer_lookup(ns, zone, type)
          write_cache(ns, zone, type, retval)
          puts "(fetched)"
          return retval
        end
      end

      raise "Didn't get an answer from any nameserver"

    end

    private

    def get_answer_lookup(ns, zone, type)
      answer, name = nil
      Resolv::DNS.new(:nameserver => [ns]).fetch_resource(zone, type) {|*args| answer, name = args}
      if name != Resolv::DNS::Name.create(zone)
        raise "wut, asked for #{zone.inspect} got #{name.inspect}"
      end
      answer
    end

    def read_cache(ns, zone, type, now = nil)
      data = begin
        IO.read(cache_file(ns, zone, type))
      rescue Errno::ENOENT
        return nil
      end
      time, retval = Marshal.restore data

      p time
      p retval

      if answer_expired?(retval, time, now)
        puts "cached but expired"
        return nil
      end

      retval
    end

    def write_cache(ns, zone, type, retval, now = nil)
      now ||= Time.now
      data = Marshal.dump([ now, retval ])
      # TODO tmp + rename
      IO.write(cache_file(ns, zone, type), data)
    end

    def cache_file(ns, zone, type)
      "#{@dir}/#{ns}-#{zone.to_s}-#{type.name}"
    end

    def answer_expired?(answer, time, now)
      now ||= Time.now
      age = now - time

      min_ttl = find_min_rr_ttl(answer)
      age > min_ttl
    end

    def find_min_rr_ttl(answer)
      %w[ answer authority additional ].map do |set|
        answer.send(set.to_sym).map do |name, ttl, rr_with_ttl|
          ttl
        end
      end.flatten.min || 0
    end

  end

end
