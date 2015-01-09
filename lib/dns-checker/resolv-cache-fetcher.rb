module DNSChecker

  class ResolvCacheFetcher

    def get_answer_lookup(ns, zone, type)
      answer, name = nil
      Resolv::DNS.new(:nameserver => [ns]).fetch_resource(zone, type) {|*args| answer, name = args}
      if name and name != Resolv::DNS::Name.create(zone)
        raise "wut, asked for #{zone.inspect} got #{name.inspect}"
      end
      answer
    end

  end

end
