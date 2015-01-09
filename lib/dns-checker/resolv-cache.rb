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
      answer, name = nil
      Resolv::DNS.new(:nameserver => [ns]).fetch_resource(zone, type) {|*args| answer, name = args}
      if name and name != Resolv::DNS::Name.create(zone)
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
      time, answer = Marshal.restore data

      if answer_expired?(answer, time, now)
        puts "cached but expired"
        return nil
      end

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
