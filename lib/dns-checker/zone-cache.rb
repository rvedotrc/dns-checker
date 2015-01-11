module DNSChecker

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

    attr_accessor :cache

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

      # FIXME shouldn't be necessary because Resolv::DNS::Name appears to
      # /try/ to be case-insensitive, case-preserving.  But, doesn't seem to
      # work.
      zone = Resolv::DNS::Name.create(zone.to_s.downcase)

      while true
        puts "Looking in zone cache for #{zone}"
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

      # FIXME shouldn't be necessary because Resolv::DNS::Name appears to
      # /try/ to be case-insensitive, case-preserving.  But, doesn't seem to
      # work.
      zone = Resolv::DNS::Name.create(zone.to_s.downcase)

      nameservers.kind_of? Set or raise
      puts "Adding #{zone} to zone cache"
      @cache[zone] = Set.new nameservers
    end

  end

end
