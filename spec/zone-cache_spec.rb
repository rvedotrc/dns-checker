require 'dns-checker'

describe DNSChecker::ZoneCache do

  def name(s)
    Resolv::DNS::Name.create(s)
  end

  def names(l)
    Set.new(l.map {|s| name(s)})
  end

  before do
    @zone_cache = DNSChecker::ZoneCache.new
    @root = name(".")
  end

  def expect_zone(look_for, expect_find)
    expect(@zone_cache.find_closest_zone(name(look_for))[:zone]).to eq(name(expect_find))
  end

  it "should start off with just the root zone" do
    @zone_cache = DNSChecker::ZoneCache.new
    expect(@zone_cache.cache.keys.count).to eq(1)
    expect(@zone_cache.cache.keys).to eq([ @root ])
  end

  it "should have the nameservers for the root zone" do
    root_answer = @zone_cache.find_closest_zone(@root)
    expect(root_answer[:zone]).to eq(@root)
    expect(root_answer[:nameservers].count).to eq(13)
  end

  it "should be able to add zones" do
    @zone_cache.add_zone(name("com."), names(%w[ com1 com2 com3 ]))
    @zone_cache.add_zone(name("org."), names(%w[ org1 org2 ]))
    @zone_cache.add_zone(name("net."), names(%w[ net1 ]))

    org = @zone_cache.find_closest_zone(name("org."))
    expect(org[:zone]).to eq(name("org."))
    expect(org[:nameservers].count).to eq(2)
  end

  it "should find the closest zone" do
    @zone_cache.add_zone(name("com."), names(%w[ com1 com2 com3 ]))
    @zone_cache.add_zone(name("example.com."), names(%w[ ex1 ex2 ]))
    @zone_cache.add_zone(name("a.b.example.com."), names(%w[ a1 ]))

    expect_zone ".", "."
    expect_zone "com.", "com."
    expect_zone "example.com.", "example.com."
    expect_zone "b.example.com.", "example.com." # NOT b.example.com.
    expect_zone "a.b.example.com.", "a.b.example.com."

    expect_zone "another.com.", "com."
  end

  it "should treat zones case-insensitively" do
    @zone_cache.add_zone(name("com."), names(%w[ com1 com2 com3 ]))
    @zone_cache.add_zone(name("EXAMPLE.com."), names(%w[ ex1 ex2 ]))

    expect_zone "com.", "com."
    expect_zone "example.com.", "example.com."
    expect_zone "EXAMPLE.COM.", "EXAMPLE.com."
    expect_zone "example.COM.", "EXAMPLE.com."
    expect_zone "EXAMPLE.com.", "example.com."
  end

  # TODO should expect Set
  # TODO should replace previous nameservers (or should we just fail if
  # already present?)

end
