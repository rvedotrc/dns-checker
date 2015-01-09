require 'resolv'
require 'set'

module DNSChecker
  
  <<-EOF
  - seed hostname cache
  - seed zone cache

  Algorithm:
    - find the closest zone we know about so far (which might be the root)
      - implies storing the following about each zone: zone, nameservers (names)
    - resolve names to ips (use cache; if missing, look up. recurses here. watch for loops)
    - make query using nameservers
    - if valid referral, add to zone cache, and repeat from step 1
    - answer (if any)
  EOF

  module FullResolver

    class ZoneCache

      ROOT_NAMESERVERS = <<-EOF
.                        3600000      NS    A.ROOT-SERVERS.NET.
.                        3600000      NS    B.ROOT-SERVERS.NET.
.                        3600000      NS    C.ROOT-SERVERS.NET.
.                        3600000      NS    D.ROOT-SERVERS.NET.
.                        3600000      NS    E.ROOT-SERVERS.NET.
.                        3600000      NS    F.ROOT-SERVERS.NET.
.                        3600000      NS    G.ROOT-SERVERS.NET.
.                        3600000      NS    H.ROOT-SERVERS.NET.
.                        3600000      NS    I.ROOT-SERVERS.NET.
.                        3600000      NS    J.ROOT-SERVERS.NET.
.                        3600000      NS    K.ROOT-SERVERS.NET.
.                        3600000      NS    L.ROOT-SERVERS.NET.
.                        3600000      NS    M.ROOT-SERVERS.NET.
      EOF

      def initialize
        @cache = {}

        ROOT_NAMESERVERS.each_line do |line|
          zone, ttl, type, nameserver = line.split
          name = Resolv::DNS::Name.create(zone)
          (@cache[name] ||= Set.new) << Resolv::DNS::Name.create(nameserver.downcase)
        end
      end

      def find_closest_zone(zone)
        zone.kind_of? Resolv::DNS::Name or raise
        while true
          answer = @cache[zone]
          if answer
            return { zone: zone, nameservers: answer }
          end
          raise "Who stole the root zone?" if zone.root?
          zone = zone.parent
        end
      end

      def add_zone(zone, nameservers)
        zone.kind_of? Resolv::DNS::Name or raise "Expected a name, got #{zone.inspect}"
        nameservers.kind_of? Set or raise
        @cache[zone] = Set.new nameservers
      end

    end

    class HostCache

      ROOT_NS_ADDRS = <<-EOF
A.ROOT-SERVERS.NET.      3600000      A     198.41.0.4
A.ROOT-SERVERS.NET.      3600000      AAAA  2001:503:BA3E::2:30
B.ROOT-SERVERS.NET.      3600000      A     192.228.79.201
C.ROOT-SERVERS.NET.      3600000      A     192.33.4.12
D.ROOT-SERVERS.NET.	 3600000      AAAA  2001:500:2D::D
D.ROOT-SERVERS.NET.      3600000      A     199.7.91.13
E.ROOT-SERVERS.NET.      3600000      A     192.203.230.10
F.ROOT-SERVERS.NET.      3600000      A     192.5.5.241
F.ROOT-SERVERS.NET.      3600000      AAAA  2001:500:2F::F
G.ROOT-SERVERS.NET.      3600000      A     192.112.36.4
H.ROOT-SERVERS.NET.      3600000      A     128.63.2.53
H.ROOT-SERVERS.NET.      3600000      AAAA  2001:500:1::803F:235
I.ROOT-SERVERS.NET.      3600000      A     192.36.148.17
I.ROOT-SERVERS.NET.      3600000      AAAA  2001:7FE::53
J.ROOT-SERVERS.NET.      3600000      A     192.58.128.30
J.ROOT-SERVERS.NET.      3600000      AAAA  2001:503:C27::2:30
K.ROOT-SERVERS.NET.      3600000      A     193.0.14.129
K.ROOT-SERVERS.NET.      3600000      AAAA  2001:7FD::1
L.ROOT-SERVERS.NET.      3600000      A     199.7.83.42
L.ROOT-SERVERS.NET.      3600000      AAAA  2001:500:3::42
M.ROOT-SERVERS.NET.      3600000      A     202.12.27.33
M.ROOT-SERVERS.NET.      3600000      AAAA  2001:DC3::35
      EOF

      def initialize
        @cache = {}

        ROOT_NS_ADDRS.each_line do |line|
          hostname, ttl, type, addr = line.split
          (@cache[Resolv::DNS::Name.create hostname.downcase] ||= Set.new) << addr.downcase
        end
      end

      def get(hostname)
        @cache[hostname.downcase]
      end

      def put(hostname, addrs)
        @cache[hostname.downcase] = addrs.map &:downcase
      end

    end

    class Resolver

      attr_reader :zone_cache, :host_cache, :query_cache

      def initialize(zone_cache, host_cache, query_cache)
        @zone_cache = zone_cache
        @host_cache = host_cache
        @query_cache = query_cache
        @level = 0
      end

      def puts(string)
        print "    " * @level
        super
      end

      def find_answer(name, type)

        while true
          puts ""
          puts "Trying to find #{type.inspect} #{name.inspect}"

          closest = @zone_cache.find_closest_zone(name)
          closest_zone, nameservers = closest[:zone], closest[:nameservers]
          puts "Closest zone so far is #{closest_zone.inspect} with nameservers #{nameservers.inspect}"

          nameserver_addresses = nameservers.map {|ns| resolve_name_to_addresses ns}\
            .reduce([]) {|arr,nss| arr.concat nss.to_a; arr}
          puts "Zone #{closest_zone.inspect} nameservers resolve to #{nameserver_addresses.inspect}"

          answer = @query_cache.get_answer(nameserver_addresses, name, type)
          puts "Got answer"

          next_zone, next_nameservers = find_referral(answer, closest_zone, name)
          if next_zone
            puts "Is referral to zone #{next_zone.inspect} using nameservers #{next_nameservers.inspect}"
            @zone_cache.add_zone(next_zone, Set.new(next_nameservers))
            next
          end

          puts "Not a referral"
          puts "Got answer: #{answer.inspect}"
          return answer
        end

      end

      def resolve_name_to_addresses(name)
        addresses = @host_cache.get(name)
        return addresses if addresses

        # TODO replace by a re-entrant lookup
        # In any case, this just finds a single IPv4 - no support for >1
        # address, nor IPv6
        addresses = [ Resolv.getaddress(name.to_s) ]

        @host_cache.put(name, addresses)
        addresses
      end

      def find_referral(answer, in_zone, target_zone_name)
        valid_authorities = answer.authority.select do |auth_zone, ttl, auth_rr|
          auth_rr.kind_of? Resolv::DNS::Resource::IN::NS \
            and auth_zone.subdomain_of?(in_zone) \
            and auth_zone.same_or_ancestor_of?(target_zone_name)
        end

        return nil if valid_authorities.empty?

        next_zone = valid_authorities.map {|auth| auth[0]}
        if next_zone.uniq.count > 1
          raise "Conflicting next-zones: #{next_zone}"
        end
        next_zone = next_zone.first

        next_server_names = valid_authorities.map {|auth| auth[2].name}
        puts "#{in_zone.inspect} delegates to #{next_zone.inspect} via #{next_server_names.inspect}"

        [ next_zone, next_server_names ]
      end

    end

  end

end

class Resolv
  class DNS
    class Name
      def downcase
        self
      end
      def root?
        raise unless absolute?
        to_a.empty?
      end
      def parent
        raise unless absolute?
        Resolv::DNS::Name.create(to_a[1..-1].join(".")+".")
      end
    end
  end
end
