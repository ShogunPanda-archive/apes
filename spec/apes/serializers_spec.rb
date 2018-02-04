#
# This file is part of the apes gem. Copyright (C) 2016 and above Shogun <shogun@cowtech.it>.
# Licensed under the MIT license, which can be found at https://choosealicense.com/licenses/mit.
#

require "spec_helper"

describe Apes::Serializers::List do
  describe ".load" do
    it "split a string" do
      expect(Apes::Serializers::List.load(", 1,2 4,,3,A , B   ")).to eq(["1", "2 4", "3", "A", "B"])
    end
    
    it "always returns a array" do
      expect(Apes::Serializers::List.load(nil)).to eq([])
    end
  end
  
  describe ".dump" do
    it "encodes everything as an array" do
      expect(Apes::Serializers::List.dump([])).to eq("")
      expect(Apes::Serializers::List.dump([1, "2", 3])).to eq("1,2,3")
      expect(Apes::Serializers::List.dump(1)).to eq("1")
    end
  end
end

describe Apes::Serializers::JSON do
  describe ".load" do
    it "load a JSON object" do
      expect(Apes::Serializers::JSON.load("{\"1\": 2}")).to eq({"1" => 2})
    end
    
    it "an Hash is returned with indifferent access" do
      expect(Apes::Serializers::JSON.load("{\"1\": 2}")).to be_a(HashWithIndifferentAccess)
    end
    
    it "fallbacks to default for invalid JSON" do
      expect(Apes::Serializers::JSON.load("\"", false, "A")).to eq("A")
    end
  end
  
  describe ".dump" do
    it "encodes input as JSON" do
      expect(Apes::Serializers::JSON.dump({a: "B"})).to eq("{\"a\":\"B\"}")
    end
  end
end

describe Apes::Serializers::JWT do
  describe ".load" do
    it "load a JSON object" do
      expect(Apes::Serializers::JWT.load("eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJhdWQiOiJkYXRhIiwic3ViIjp7IjEiOjJ9fQ.jqhJuB0xtO7Xyk_T8X_rwOKE96Q7GBxWR5NBxfW5xWE")).to eq({"1" => 2})
    end
    
    it "an Hash is returned with indifferent access" do
      expect(Apes::Serializers::JWT.load("eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJhdWQiOiJkYXRhIiwic3ViIjp7IjEiOjJ9fQ.jqhJuB0xtO7Xyk_T8X_rwOKE96Q7GBxWR5NBxfW5xWE")).to be_a(HashWithIndifferentAccess)
    end
    
    it "fallbacks to default for invalid JSON" do
      expect(Apes::Serializers::JWT.load("\"", false, "A")).to eq("A")
    end
  end
  
  describe ".dump" do
    it "encodes input as JSON" do
      expect(Apes::Serializers::JWT.dump({a: "B"})).to eq("eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJhdWQiOiJkYXRhIiwic3ViIjp7ImEiOiJCIn19.mWyWy9SDzOlBLJW1b4ICw4QZwoGDU836ED5EALZnjeU")
    end
  end
end