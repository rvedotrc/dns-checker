require 'dns-checker'

describe Resolv::DNS::Name do

  def name(s)
    Resolv::DNS::Name.create(s)
  end

  it "should compare case-insensitively" do
    expect(name("example.com.")).to eq(name("EXAMPLE.com."))
    expect(name("example.com.") == name("EXAMPLE.com.")).to be_truthy
    expect(name("example.com.").eql? name("EXAMPLE.com.")).to be_truthy
  end

  it "should not throw away dots when comparing" do
    expect(name("example.com.")).not_to eq(name("ex.am.ple.com."))
    expect(name("example.com.") == name("ex.am.ple.com.")).to be_falsy
    expect(name("example.com.").eql? name("ex.am.ple.com.")).to be_falsy
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

  # to_s doesn't add the trailing dot on absolute names
  it "should support to_s_normalised" do
    expect(name("EXAMPLE.COM.").to_s_normalised).to eq("example.com.")
    expect(name("EXAMPLE.COM").to_s_normalised).to eq("example.com")
    expect(name("COM.").to_s_normalised).to eq("com.")
    expect(name("COM").to_s_normalised).to eq("com")
    expect(name(".").to_s_normalised).to eq(".")
  end

  it "should support normalise" do
    expect(name("EXAMPLE.COM.").normalise).to eq(name("example.com."))
    expect(name("EXAMPLE.COM.").normalise.to_s).to eq("example.com")
    expect(name("EXAMPLE.COM").normalise).to eq(name("example.com"))
    expect(name("EXAMPLE.COM").normalise.to_s).to eq("example.com")
  end

end
