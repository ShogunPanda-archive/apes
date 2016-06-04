#
# This file is part of the apes gem. Copyright (C) 2016 and above Shogun <shogun@cowtech.it>.
# Licensed under the MIT license, which can be found at http://www.opensource.org/licenses/mit-license.php.
#

require "spec_helper"

describe Apes::RuntimeConfiguration do
  describe ".jwt_token" do
    it "should get the information from Rails secrets" do
      stub_const("Rails", {application: {secrets: {jwt: "SECRET"}}}.ensure_access(:dotted))
      expect(Apes::RuntimeConfiguration.jwt_token).to eq("SECRET")
    end

    it "should fallback to a default" do
      expect(Apes::RuntimeConfiguration.jwt_token).to eq("secret")
      expect(Apes::RuntimeConfiguration.jwt_token("DEFAULT")).to eq("DEFAULT")
    end
  end

  describe ".timestamp_formats" do
    it "should get the information from Rails secrets" do
      stub_const("Rails", {application: {config: {timestamp_formats: {a: 1}}}}.ensure_access(:dotted))
      expect(Apes::RuntimeConfiguration.timestamp_formats).to eq({a: 1})
    end

    it "should fallback to a default" do
      expect(Apes::RuntimeConfiguration.timestamp_formats).to eq({})
      expect(Apes::RuntimeConfiguration.timestamp_formats("DEFAULT")).to eq("DEFAULT")
    end
  end

  describe ".rails_root" do
    it "should get the information from Rails" do
      stub_const("Rails", {root: "/ABC"}.ensure_access(:dotted))
      expect(Apes::RuntimeConfiguration.rails_root).to eq("/ABC")
    end

    it "should fallback to a default" do
      allow(Rails).to receive(:root).and_raise(RuntimeError)

      expect(Apes::RuntimeConfiguration.rails_root).to be_nil
      expect(Apes::RuntimeConfiguration.rails_root("DEFAULT")).to eq("DEFAULT")
    end
  end

  describe ".gems_root" do
    it "should get the information from Rails" do
      expect(Apes::RuntimeConfiguration.gems_root).to be_a(String)
    end

    it "should fallback to a default" do
      allow(Gem).to receive(:loaded_specs).and_raise(RuntimeError)

      expect(Apes::RuntimeConfiguration.gems_root).to be_nil
      expect(Apes::RuntimeConfiguration.gems_root("DEFAULT")).to eq("DEFAULT")
    end
  end
end