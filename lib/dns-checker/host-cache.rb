module DNSChecker

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

    attr_reader :cache

    def initialize
      @cache = {}

      ROOT_NS_ADDRS.each_line do |line|
        hostname, ttl, type, addr = line.split
        (@cache[Resolv::DNS::Name.create hostname.downcase] ||= Set.new) << addr.downcase
      end
    end

    def get(hostname)
      # FIXME shouldn't be necessary because Resolv::DNS::Name appears to
      # /try/ to be case-insensitive, case-preserving.  But, doesn't seem to
      # work.
      hostname = Resolv::DNS::Name.create(hostname.to_s.downcase + ".")

      @cache[hostname]
    end

    def put(hostname, addrs)
      # FIXME shouldn't be necessary because Resolv::DNS::Name appears to
      # /try/ to be case-insensitive, case-preserving.  But, doesn't seem to
      # work.
      hostname = Resolv::DNS::Name.create(hostname.to_s.downcase + ".")

      (@cache[hostname] ||= []).concat addrs.to_a
      @cache[hostname].uniq!
    end

  end

end
