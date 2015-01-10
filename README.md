DNS Dependency Checker
======================

A tool for performing DNS lookups, in order to show:

 * which zones this zone depends on (security)
 * which zones are accessible to IPv6 clients (reachability)

Requirements
------------

 * ruby
 * make
 * graphviz (to render the diagram)
 * a network setup that allows you to make DNS lookups against arbitrary Internet hosts (some corporate private networks don't)

Limitations
-----------

When performing lookups, the script chooses a nameserver at random.
If it chooses an IPv6 server and your host doesn't have an IPv6 Internet
connection, the lookup will fail. (And the same for IPv4).

Doesn't deal well with errors, including CNAME nameservers, SERVFAIL, lame
(non-authoritative) servers, or zones incorrectly set up to depend on each
other's nameservers.

Doesn't understand IDN at all.

Use
---

Just run `./dns-dependency-walker --help` for help.

`mkdir -p var/cache`

`./do [options] ZONE`

e.g.

`./do org`

`./do --show-ipv6-errors facebook.com`

`./do --show-ipv6-errors gov.uk`

`./do --show-nameservers --group-nameservers --show-ipv6-errors wikipedia.org`

Possible future additions
-------------------------

In no particular order,

 * Avoid using IPv6 hosts if we don't have IPv6 (see "Limitations")
 * Avoid using IPv4 hosts if we don't have IPv4 (see "Limitations")
 * Deal with errors (see "Limitations")
 * Query all nameservers (that we can) for each zone, looking for inconsistencies 
 * Tests, cruft removal, etc.

Pull requests welcome.

