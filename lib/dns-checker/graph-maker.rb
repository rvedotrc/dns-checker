require 'resolv'
require 'set'

module DNSChecker
  
  class GraphMaker

    def dot(zone_cache)
      puts "digraph {"

      zone_cache.cache.each do |zone, nameservers|
        # A node for the zone
        puts ' %s [ label="zone\n%s" shape=rect color=blue ]' % [
          zone_node_id(zone),
          zone.to_s,
        ]

        # A node for each nameserver
        nameservers.each do |ns|
          puts ' %s [ label="ns\n%s" shape=rect color=green ]' % [
            ns_node_id(ns),
            ns.to_s,
          ]

          # Zone served by nameserver
          puts ' %s -> %s [ color=red ]' % [
            zone_node_id(zone),
            ns_node_id(ns),
          ]

          # Nameserver within zone
          ns_in_zone = zone_cache.find_closest_zone(ns.parent)[:zone]
          puts ' %s -> %s [ color=orange ]' % [
            ns_node_id(ns),
            zone_node_id(ns_in_zone),
          ]
        end

        unless zone.root?
          parent_zone = zone_cache.find_closest_zone(zone.parent)[:zone]
          # Zone delegates to zone
          puts ' %s -> %s [ color=purple ]' % [
            zone_node_id(parent_zone),
            zone_node_id(zone),
          ]
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

  end

end
