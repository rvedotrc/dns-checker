require 'resolv'
require 'set'

module DNSChecker
  
  class GraphMaker

    def initialize(zone_cache, host_cache)
      @show_each_ns = true
      @zone_cache = zone_cache
      @host_cache = host_cache
    end

    def render_dot
      puts "digraph {"

      @zone_cache.cache.each do |zone, nameservers|
        # A node for the zone
        puts ' %s [ label="%s" shape=rect %s ]' % [
          zone_node_id(zone),
          zone.to_s,
          (zone_has_ipv6(zone) ? "" : "fillcolor=grey style=filled"),
        ]

        if @show_each_ns
          nameservers.each do |ns|
            # Zone served by nameserver
            puts ' %s -> %s [ color=red ]' % [
              zone_node_id(zone),
              ns_node_id(ns),
            ]
          end
        end

        unless zone.root?
          parent_zone = @zone_cache.find_closest_zone(zone.parent)[:zone]
          # Zone delegated by zone
          puts ' %s -> %s [ color=purple ]' % [
            zone_node_id(zone),
            zone_node_id(parent_zone),
          ]
        end

      end

      if @show_each_ns
        @zone_cache.cache.values.map(&:to_a).flatten.uniq.each do |ns|
          # Nameserver node
          puts ' %s [ label="%s" shape=ellipse %s ]' % [
            ns_node_id(ns),
            ns.to_s,
            (host_has_ipv6(ns) ? "" : "fillcolor=grey style=filled"),
          ]

          # Nameserver within zone
          ns_in_zone = @zone_cache.find_closest_zone(ns)[:zone]
          puts ' %s -> %s [ color=orange ]' % [
            ns_node_id(ns),
            zone_node_id(ns_in_zone),
          ]
        end
      else
        done = {}

        @zone_cache.cache.each do |zone, nameservers|
          nameservers.each do |ns|
            ns_in_zone = @zone_cache.find_closest_zone(ns)[:zone]
            key = [ zone, ns_in_zone ]
            if !done[key]
              # Zone has nameserver(s) in zone
              puts ' %s -> %s [ color=orange ]' % [
                zone_node_id(zone),
                zone_node_id(ns_in_zone),
              ]
              done[key] = true
            end
          end
        end

      end

      puts "}"
    end

    def zone_node_id(zone)
      "zone_" + zone.to_s.gsub("-", "__").gsub(".", "_")
    end

    def ns_node_id(ns)
      "ns_" + ns.to_s.gsub("-", "__").gsub(".", "_")
    end

    def host_has_ipv6(host)
      @host_cache.get(host).any? {|addr| addr.match /:/} # Eww
    end

    def zone_has_ipv6(zone)
      return false if @zone_cache.cache[zone].none? {|ns| host_has_ipv6(ns)}

      return true if zone.root?

      parent = @zone_cache.find_closest_zone(zone.parent)[:zone]
      return zone_has_ipv6(parent)
    end

    def log(*s)
      $stderr.puts *s
    end

  end

end
