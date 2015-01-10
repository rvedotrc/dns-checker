require_relative 'dns-checker/root-servers'
require_relative 'dns-checker/resolv-cache'
require_relative 'dns-checker/resolv-cache-fetcher'
require_relative 'dns-checker/resolv-cache-store'
require_relative 'dns-checker/zone-walker'
require_relative 'dns-checker/full-resolver'
require_relative 'dns-checker/host-cache'
require_relative 'dns-checker/zone-cache'
require_relative 'dns-checker/graph-maker'

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
