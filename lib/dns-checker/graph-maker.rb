require 'resolv'
require 'set'

module DNSChecker
  
  class GraphMaker

    def initialize
      @show_each_ns = true
    end

    def dot(zone_cache)
      puts "digraph {"

      zone_cache.cache.each do |zone, nameservers|
        # A node for the zone
        puts ' %s [ label="zone\n%s" shape=rect color=blue ]' % [
          zone_node_id(zone),
          zone.to_s,
        ]

        if @show_each_ns
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
          end
        end

        unless zone.root?
          parent_zone = zone_cache.find_closest_zone(zone.parent)[:zone]
          # Zone delegated by zone
          puts ' %s -> %s [ color=purple ]' % [
            zone_node_id(zone),
            zone_node_id(parent_zone),
          ]
        end

      end

      if @show_each_ns
        zone_cache.cache.values.map(&:to_a).flatten.uniq.each do |ns|
          # Nameserver within zone
          ns_in_zone = zone_cache.find_closest_zone(ns)[:zone]
          puts ' %s -> %s [ color=orange ]' % [
            ns_node_id(ns),
            zone_node_id(ns_in_zone),
          ]
        end
      else
        done = {}

        zone_cache.cache.each do |zone, nameservers|
          nameservers.each do |ns|
            ns_in_zone = zone_cache.find_closest_zone(ns)[:zone]
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

  end

end
