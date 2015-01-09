module DNSChecker

  class ZoneWalker

    attr_accessor :cache, :root_servers

    def initialize(cache, root_servers)
      @cache = cache
      @root_servers = root_servers
    end

    def walk(target_zone_string)
      target_zone_string.end_with? "." or raise "zone must end with dot"
      target_zone_name = Resolv::DNS::Name.create(target_zone_string)

      in_zone = Resolv::DNS::Name.create(".")
      servers = @root_servers

      while true

        puts ""
        puts "Goal: #{target_zone_string.inspect} = #{target_zone_name.inspect}"
        puts "Currently in zone #{in_zone.inspect}"
        puts "Asking #{servers} about #{target_zone_string}"
        answer = cache.get_answer(servers, target_zone_string, Resolv::DNS::Resource::IN::ANY)

        # TODO check qr, aa, rcode, tc, and so forth
        # Note: no information about which server gave us this response.
        # We could ask them all and see if they agree.

        #answer.authority.each do |auth|
        #  puts "authority #{auth}"
        #end

        #puts "Looking for next-zone referrals"

        valid_authorities = answer.authority.select do |auth_zone, ttl, auth_rr|
          auth_rr.kind_of? Resolv::DNS::Resource::IN::NS \
            and auth_zone.subdomain_of?(in_zone) \
            and auth_zone.same_or_ancestor_of?(target_zone_name)
        end

        #puts "Referral authorities = #{valid_authorities.inspect}"

        if !valid_authorities.empty?
          next_zone = valid_authorities.map {|auth| auth[0]}
          if next_zone.uniq.count > 1
            raise "Conflicting next-zones under #{target_zone_string}: #{next_zone}"
          end
          next_zone = next_zone.first

          next_server_names = valid_authorities.map {|auth| auth[2].name}
          puts "#{in_zone} delegates to #{next_zone} via #{next_server_names.map {|n| n.to_s}}"

          next_server_addrs = next_server_names.map {|name| Resolv.getaddress name.to_s}
          puts "server ip addresses are #{next_server_addrs}"

          in_zone = next_zone
          servers = next_server_addrs
          next
        end

        puts ""
        puts "Didn't get a referral"
        p answer
        answer.answer.each do |name, ttl, rr_with_ttl|
          puts "answer #{name} #{rr_with_ttl.inspect}"
        end

        break
      end

    end

  end

end

class Resolv
  class DNS
    class Name
      def same_or_subdomain_of?(other)
        subdomain_of?(other) or self == other
      end
      def ancestor_of?(other)
        other.subdomain_of? self
      end
      def same_or_ancestor_of?(other)
        ancestor_of?(other) or self == other
      end

      def inspect
        "#<#{self.class}: #{self.to_s}>"
      end
      def to_s
        to_a.join(".") + (absolute? ? "." : "")
      end
    end
  end
end

