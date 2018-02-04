#
# This file is part of the apes gem. Copyright (C) 2016 and above Shogun <shogun@cowtech.it>.
# Licensed under the MIT license, which can be found at https://choosealicense.com/licenses/mit.
#

require "spec_helper"

describe Apes::UrlsParser do
  describe ".instance" do
    it "should return a singleton" do
      first = Apes::UrlsParser.instance
      expect(Apes::UrlsParser.instance).to be(first)
    end
    
    it "should force recreation of a new singleton" do
      original = Apes::UrlsParser.instance
      expect(Apes::UrlsParser.instance).to be(original)
      expect(Apes::UrlsParser.instance(true)).not_to be(original)
    end
  end
  
  describe "#url?" do
    it "should recognize whether a text is a url" do
      expect(Apes::UrlsParser.instance.url?("http://google.it")).to be_truthy
      expect(Apes::UrlsParser.instance.url?("google.co")).to be_truthy
      expect(Apes::UrlsParser.instance.url?("fab.foog.google.co")).to be_truthy
      expect(Apes::UrlsParser.instance.url?("google.co:123/abc?query=a&utc=b#whatever")).to be_truthy
      expect(Apes::UrlsParser.instance.url?("google.ca#123")).to be_truthy
      expect(Apes::UrlsParser.instance.url?("google.c")).to be_falsey
      expect(Apes::UrlsParser.instance.url?("http://google.cowtech")).to be_falsey
      expect(Apes::UrlsParser.instance.url?("http://google.it::123")).to be_falsey
      expect(Apes::UrlsParser.instance.url?("fab..foog.google.co")).to be_falsey
      expect(Apes::UrlsParser.instance.url?("test@google.com")).to be_falsey
      expect(Apes::UrlsParser.instance.url?("http://127.0.0.1")).to be_truthy
      expect(Apes::UrlsParser.instance.url?("127.0.0.1")).to be_truthy
      expect(Apes::UrlsParser.instance.url?("http://[1762:0:0:0:0:B03:1:AF18]")).to be_truthy
      expect(Apes::UrlsParser.instance.url?("[1762::B03:1:AF18]")).to be_truthy
      expect(Apes::UrlsParser.instance.url?("[::127.0.0.1]")).to be_truthy
    end
  end
  
  describe "#email?" do
    it "should recognize whether a text is a email" do
      expect(Apes::UrlsParser.instance.email?("abc@google.it")).to be_truthy
      expect(Apes::UrlsParser.instance.email?("abc.cde@google.co")).to be_truthy
      expect(Apes::UrlsParser.instance.email?("ab'c.cde@google.co")).to be_truthy
      expect(Apes::UrlsParser.instance.email?("abc-af_123@fab.foog.google.co")).to be_truthy
      expect(Apes::UrlsParser.instance.email?("ad$1@local.com")).to be_falsey
    end
  end
  
  describe "#domain?" do
    it "should recognize whether a text is a domain" do
      expect(Apes::UrlsParser.instance.domain?("google.it")).to be_truthy
      expect(Apes::UrlsParser.instance.domain?("google.co")).to be_truthy
      expect(Apes::UrlsParser.instance.domain?("fab.foog.google.co")).to be_truthy
      expect(Apes::UrlsParser.instance.domain?("google.co:123/abc?query=a&utc=b#whatever")).to be_falsey
      expect(Apes::UrlsParser.instance.domain?("google.c")).to be_falsey
      expect(Apes::UrlsParser.instance.domain?("google.it:123")).to be_falsey
    end
  end
  
  describe "#shortened?" do
    it "should recognize whether a URL is a shortened one" do
      expect(Apes::UrlsParser.instance.shortened?("https://bit.ly/ABC")).to be_truthy
      expect(Apes::UrlsParser.instance.shortened?("bit.ly/ABC")).to be_truthy
      expect(Apes::UrlsParser.instance.shortened?("bit.ly/ACC")).to be_truthy
      expect(Apes::UrlsParser.instance.shortened?("cow.tc/ACC")).to be_falsey
      expect(Apes::UrlsParser.instance.shortened?("cow.tc/ACC", "cow.tc")).to be_truthy
      expect(Apes::UrlsParser.instance.shortened?("abit.ly/ACC")).to be_falsey
    end
  end
  
  describe "#extract_urls" do
    it "should extract URLS from a text" do
      text = "
        This is a pretty complex text. It has a URL without a domain which is google.it, also it contains a separator and now let's also put two
        overlapping URLs http://cowtech.it and http://cowtech.it/en and, finally, a shortened one http://bit.ly/1000 and one using custom domain
        http://cnn.it/1GFkZQs and email test@gmail.com. Fun, isn't it?
      "
      
      expect(Apes::UrlsParser.instance.extract_urls(text)).to eq(["google.it", "http://cowtech.it", "http://cowtech.it/en", "http://bit.ly/1000", "http://cnn.it/1GFkZQs"])
      expect(Apes::UrlsParser.instance.extract_urls(text, sort: :asc)).to eq(["google.it", "http://cowtech.it", "http://bit.ly/1000", "http://cowtech.it/en", "http://cnn.it/1GFkZQs"])
      expect(Apes::UrlsParser.instance.extract_urls(text, sort: :desc)).to eq(["http://cnn.it/1GFkZQs", "http://cowtech.it/en", "http://bit.ly/1000", "http://cowtech.it", "google.it"])
      expect(Apes::UrlsParser.instance.extract_urls(text, mode: :shortened)).to eq(["http://bit.ly/1000"])
      expect(Apes::UrlsParser.instance.extract_urls(text, mode: :unshortened)).to eq(["google.it", "http://cowtech.it", "http://cowtech.it/en", "http://cnn.it/1GFkZQs"])
      expect(Apes::UrlsParser.instance.extract_urls(text, mode: :shortened, shortened_domains: ["cnn.it"])).to eq(["http://bit.ly/1000", "http://cnn.it/1GFkZQs"])
      expect(Apes::UrlsParser.instance.extract_urls(text, mode: :unshortened, shortened_domains: ["cnn.it"])).to eq(["google.it", "http://cowtech.it", "http://cowtech.it/en"])
    end
  end
  
  describe "#replace_urls" do
    it "should replace URLS in a text" do
      text = "
        This is a pretty complex text. It has a URL without a domain which is google.it, also it contains a separator and now let's also put two
        overlapping URLs http://cowtech.it and http://cowtech.it/en and, finally, a shortened one http://bit.ly/1000 and one using custom domain
        http://cnn.it/1GFkZQs. Fun, isn't it?
      "
      
      replacements = {
        "http://cowtech.it" => "A",
        "http://cowtech.it/en" => "B",
        "http://bit.ly/1000" => "C",
        "http://cnn.it/1GFkZQs" => "D"
      }
      
      expect(Apes::UrlsParser.instance.replace_urls(text, replacements: replacements)).to eq("
        This is a pretty complex text. It has a URL without a domain which is google.it, also it contains a separator and now let's also put two
        overlapping URLs http://A and http://B and, finally, a shortened one http://C and one using custom domain
        http://D. Fun, isn't it?
      ")
      
      expect(Apes::UrlsParser.instance.replace_urls(text, replacements: replacements, mode: :unshortened)).to eq("
        This is a pretty complex text. It has a URL without a domain which is google.it, also it contains a separator and now let's also put two
        overlapping URLs http://A and http://B and, finally, a shortened one http://bit.ly/1000 and one using custom domain
        http://D. Fun, isn't it?
      ")
      
      expect(Apes::UrlsParser.instance.replace_urls(text, replacements: replacements, mode: :shortened)).to eq("
        This is a pretty complex text. It has a URL without a domain which is google.it, also it contains a separator and now let's also put two
        overlapping URLs http://cowtech.it and http://cowtech.it/en and, finally, a shortened one http://C and one using custom domain
        http://cnn.it/1GFkZQs. Fun, isn't it?
      ")
      
      expect(Apes::UrlsParser.instance.replace_urls(text, replacements: replacements, mode: :shortened, shortened_domains: ["cnn.it"])).to eq("
        This is a pretty complex text. It has a URL without a domain which is google.it, also it contains a separator and now let's also put two
        overlapping URLs http://cowtech.it and http://cowtech.it/en and, finally, a shortened one http://C and one using custom domain
        http://D. Fun, isn't it?
      ")
    end
  end
  
  describe "#clean" do
    it "should remove separators after a url" do
      expect(Apes::UrlsParser.instance.clean(" http://google.it ")).to eq("http://google.it")
      expect(Apes::UrlsParser.instance.clean(" http://google.it,")).to eq("http://google.it")
      expect(Apes::UrlsParser.instance.clean(" http://google.it.")).to eq("http://google.it")
      expect(Apes::UrlsParser.instance.clean(" http://google.it:")).to eq("http://google.it")
    end
  end
  
  describe "#hashify" do
    it "should generate a hash out of a URL" do
      expect(Apes::UrlsParser.instance.hashify("google.it")).to eq("dae16e97dcaa41bdace5765826a28a4192b7f2ec9d96993d158ef0413fd3cab5")
      expect(Apes::UrlsParser.instance.hashify("http://google.it")).to eq("dae16e97dcaa41bdace5765826a28a4192b7f2ec9d96993d158ef0413fd3cab5")
      expect(Apes::UrlsParser.instance.hashify("bit.ly/1000")).to eq("1de660471e79f834336526379fd76bebbcb69057f36237bdd82f8af58d9641de")
      expect(Apes::UrlsParser.instance.hashify("http://bit.ly/1000")).to eq("1de660471e79f834336526379fd76bebbcb69057f36237bdd82f8af58d9641de")
    end
  end
end
