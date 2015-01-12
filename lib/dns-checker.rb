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

      # We could meaningfully define aliases here:
      #     <   subdomain_of?
      #     >   ancestor_of?
      #     <=  same_or_subdomain_of?
      #     >=  same_or_ancestor_of?

      def to_s_normalised
        to_s.downcase + (absolute? ? "." : "")
      end

      def normalise
        self.class.create(to_s_normalised)
      end

      # Override broken == method
      # (already fixed upstream in ec7f1f5dc23b331e09340e0431b17eb5307aeddb, 2015-01-02)
      # 2.1.1 :001 > Resolv::DNS::Name.create("abc.def.") == Resolv::DNS::Name.create("ab.cd.ef.")
      # => true
      # 2.1.1 :002 > Resolv::DNS::Name.create("abc.def.") == Resolv::DNS::Name.create("ABC.def.")
      # => false
      def ==(other) # :nodoc:
        return false unless Name === other
        return @labels == other.to_a && @absolute == other.absolute?
      end

      def root?
        raise unless absolute?
        to_a.empty?
      end
      def parent
        raise unless absolute?
        return nil if root?
        Resolv::DNS::Name.create(to_a[1..-1].join(".")+".")
      end

    end
  end
end
