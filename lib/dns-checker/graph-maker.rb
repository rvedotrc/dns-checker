require 'resolv'
require 'set'

module DNSChecker
  
  class GraphMaker

    attr_reader :zone_cache, :host_cache, :options, :dot

    def initialize(zone_cache, host_cache, options = {})
      @zone_cache = zone_cache
      @host_cache = host_cache
      @options = options
      @dot = []
    end

    def render_dot
      dot << "digraph {"

      render_zones

      if options[:show_nameservers]
        render_nameservers
      else
        render_zone_ns_dependencies
      end

      dot << "}"

      dot.join("\n")+"\n"
    end

    def render_zones
      @zone_cache.cache.each do |zone, nameservers|
        # A node for the zone
        dot << ' %s [ label="%s" shape=rect %s ]' % [
          zone_node_id(zone),
          zone.to_s,
          (zone_reachable(zone) ? "" : "fillcolor=grey style=filled"),
        ]

        unless zone.root?
          parent_zone = @zone_cache.find_closest_zone(zone.parent)[:zone]
          # Zone delegated by zone
          dot << ' %s -> %s [ color=purple ]' % [
            zone_node_id(zone),
            zone_node_id(parent_zone),
          ]
        end
      end
    end

    def render_nameservers
      @zone_cache.cache.values.map(&:to_a).flatten.uniq.each do |ns|
        # Nameserver node
        dot << ' %s [ label="%s" shape=ellipse %s ]' % [
          ns_node_id(ns),
          ns.to_s,
          (host_reachable(ns) ? "" : "fillcolor=grey style=filled"),
        ]

        # Nameserver within zone
        ns_in_zone = @zone_cache.find_closest_zone(ns)[:zone]
        dot << ' %s -> %s [ color=orange ]' % [
          ns_node_id(ns),
          zone_node_id(ns_in_zone),
        ]
      end

      @zone_cache.cache.each do |zone, nameservers|
        nameservers.each do |ns|
          # Zone served by nameserver
          dot << ' %s -> %s [ color=red ]' % [
            zone_node_id(zone),
            ns_node_id(ns),
          ]
        end
      end
    end

    def render_zone_ns_dependencies
      done = {}

      @zone_cache.cache.each do |zone, nameservers|
        nameservers.each do |ns|
          ns_in_zone = @zone_cache.find_closest_zone(ns)[:zone]
          key = [ zone, ns_in_zone ]
          if !done[key]
            # Zone has nameserver(s) in zone
            dot << ' %s -> %s [ color=orange ]' % [
              zone_node_id(zone),
              zone_node_id(ns_in_zone),
            ]
            done[key] = true
          end
        end
      end

    end

    def zone_node_id(zone)
      "zone_" + zone.to_s.gsub("-", "__").gsub(".", "_")
    end

    def ns_node_id(ns)
      "ns_" + ns.to_s.gsub("-", "__").gsub(".", "_")
    end

    def host_reachable(host)
      log "Is #{host.inspect} reachable? #{host_cache.get(host).inspect}"
      return false if options[:show_ipv4] and host_cache.get(host).none? {|addr| addr.match /\./} # Eww
      return false if options[:show_ipv6] and host_cache.get(host).none? {|addr| addr.match /\:/} # Eww
      true
    end

    def zone_reachable(zone)
      return false if zone_cache.cache[zone].none? {|ns| host_reachable(ns)}

      return true if zone.root?

      parent = zone_cache.find_closest_zone(zone.parent)[:zone]
      return zone_reachable(parent)
    end

    def log(*s)
      puts *s
    end

  end

end
