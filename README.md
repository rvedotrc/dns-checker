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
connection, the lookup will fail.

Doesn't deal well with errors, including SERVFAIL, lame (non-authoritative) servers,
or zones incorrectly set up to depend on each other's nameservers.

Doesn't understand IDN at all.

Use
---

`mkdir -p var/cache`
`./do [options] ZONE`

e.g.

`./do org`

`./do --show-ipv6-errors facebook.com`

`./do --show-ipv6-errors gov.uk`

`./do --show-nameservers --show-ipv6-errors wikipedia.org`

