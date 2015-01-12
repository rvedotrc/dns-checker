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

  # Now on to test the helper methods we add

  it "should support root?" do
    expect(name("not-root.").root?).to be_falsy
    expect(name(".").root?).to be_truthy
    expect { name("not-absolute").root? }.to raise_error
  end

  it "should support parent" do
    expect(name("example.com.").parent).to eq(name("com."))
    expect(name("com.").parent).to eq(name("."))
    expect(name(".").parent).to be_nil
    expect { name("not-absolute.com").root? }.to raise_error
  end

  it "should support same_or_subdomain_of?" do
    expect(name("a.example.com.").same_or_subdomain_of? name("EXAMPLE.com.")).to be_truthy
    expect(name("example.com.").same_or_subdomain_of? name("EXAMPLE.com.")).to be_truthy
    expect(name("com.").same_or_subdomain_of? name("EXAMPLE.com.")).to be_falsy
    expect(name(".").same_or_subdomain_of? name("EXAMPLE.com.")).to be_falsy

    expect(name("another.net.").same_or_subdomain_of? name("EXAMPLE.com.")).to be_falsy
  end

  it "should support ancestor_of?" do
    expect(name("a.example.com.").ancestor_of? name("EXAMPLE.com.")).to be_falsy
    expect(name("example.com.").ancestor_of? name("EXAMPLE.com.")).to be_falsy
    expect(name("com.").ancestor_of? name("EXAMPLE.com.")).to be_truthy
    expect(name(".").ancestor_of? name("EXAMPLE.com.")).to be_truthy

    expect(name("another.net.").ancestor_of? name("EXAMPLE.com.")).to be_falsy
  end

  it "should support same_or_ancestor_of?" do
    expect(name("a.example.com.").same_or_ancestor_of? name("EXAMPLE.com.")).to be_falsy
    expect(name("example.com.").same_or_ancestor_of? name("EXAMPLE.com.")).to be_truthy
    expect(name("com.").same_or_ancestor_of? name("EXAMPLE.com.")).to be_truthy
    expect(name(".").same_or_ancestor_of? name("EXAMPLE.com.")).to be_truthy

    expect(name("another.net.").same_or_ancestor_of? name("EXAMPLE.com.")).to be_falsy
  end

  # Untested but currently patched: inspect, to_s

end
