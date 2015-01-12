require 'dns-checker'

describe Resolv::DNS::Name do

  def name(s)
    Resolv::DNS::Name.create(s)
  end

  it "should compare case-insensitively" do
    expect(name("example.com.")).to eq(name("EXAMPLE.com."))
  end

  it "should not throw away dots when comparing" do
    expect(name("example.com.")).not_to eq(name("ex.am.ple.com."))
  end

  it "should compare absoluteness when comparing" do
    # 2.1.0 gets this right - checking my overridden method doesn't break this
    # behaviour
    expect(name("example.com.")).to eq(name("example.com."))
    expect(name("example.com.")).not_to eq(name("example.com"))
  end

end
