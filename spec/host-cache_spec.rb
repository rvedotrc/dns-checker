require 'dns-checker'

describe DNSChecker::HostCache do

  def name(s)
    Resolv::DNS::Name.create(s)
  end

  def names(l)
    Set.new(l.map {|s| name(s)})
  end

  before do
    @host_cache = DNSChecker::HostCache.new
  end

  it "should start off with the root nameservers" do
    expect(@host_cache.cache.keys.count).to eq(13)
  end

  it "should be able to retrieve hosts" do
    h = @host_cache.get(name("m.root-servers.net."))
    expect(h.sort).to eq(%w[ 2001:dc3::35 202.12.27.33 ].sort)
  end

  it "should be able to add hosts" do
    h = @host_cache.get(name("some.name."))
    expect(h).to eq(nil)

    @host_cache.put(name("some.name."), %w[ 1.2.3.4 88.77.66.55 ])
    h = @host_cache.get(name("some.name."))
    expect(h.sort).to eq(%w[ 88.77.66.55 1.2.3.4 ].sort)
  end

  it "should treat hostnames case insensitively" do
    @host_cache.put(name("lower.case."), %w[ 1.2.3.4 88.77.66.55 ])
    @host_cache.put(name("UPPER.CASE."), %w[ 5.6.7.8 44.33.22.11 ])

    expect(@host_cache.get(name("LOWER.CASE.")).sort).to eq(%w[ 1.2.3.4 88.77.66.55 ].sort)
    expect(@host_cache.get(name("upper.case.")).sort).to eq(%w[ 5.6.7.8 44.33.22.11 ].sort)
  end

  it "should dedupe host addresses" do
    @host_cache.put(name("lower.case."), %w[ 1.2.3.4 88.77.66.55 ])
    @host_cache.put(name("lower.case."), %w[ 1.2.3.4 33.22.11.0 ])
    expect(@host_cache.get(name("lower.case.")).sort).to eq(%w[ 1.2.3.4 88.77.66.55 33.22.11.0 ].sort)
  end

end
