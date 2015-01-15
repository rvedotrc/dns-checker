module DNSChecker

  class ResolvCache

    attr_accessor :fetcher, :store

    def initialize(fetcher, store)
      @fetcher = fetcher
      @store = store
    end

    def get_answer(nameservers, zone, type)

      nameservers.each do |ns|
        if answer = read_cache(ns, zone, type)
          puts "(cached)"
          return answer
        end
      end

      nameservers.shuffle.each do |ns|
        begin
          answer = @fetcher.get_answer_lookup(ns, zone, type)
          write_cache(ns, zone, type, answer)
          puts "(fetched)"
          return answer
        rescue Errno::ENETUNREACH, Errno::EHOSTUNREACH => e
          puts "(got error #{e} while querying #{ns} - skipping this server)"
        end
      end

      raise "Didn't get an answer from any nameserver"

    end

    private

    def read_cache(ns, zone, type, now = nil)
      data = @store.get(cache_key(ns, zone, type))
      return nil if data.nil?

      time, answer = data

      if answer && answer_expired?(answer, time, now)
        puts "cached but expired"
        return nil
      end

      answer
    end

    def write_cache(ns, zone, type, answer, now = nil)
      now ||= Time.now
      data = [ now, answer ]
      @store.put(cache_key(ns, zone, type), data)
    end

    def cache_key(ns, zone, type)
      "#{ns}-#{zone.to_s}-#{type.name}"
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
