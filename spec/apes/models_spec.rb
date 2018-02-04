#
# This file is part of the apes gem. Copyright (C) 2016 and above Shogun <shogun@cowtech.it>.
# Licensed under the MIT license, which can be found at https://choosealicense.com/licenses/mit.
#

require "spec_helper"

describe Apes::Model do
  class MockBaseModel < ActiveRecord::Base
    include Apes::Model

    self.abstract_class = true
  end

  class MockQueryingModel < MockBaseModel
    SECONDARY_QUERY = "name = :id"

    def self.table_name
      "querying_temp_table"
    end

    attr_reader :field
    validates :field, "presence" => true
  end

  class MockQueryingOtherModel < MockBaseModel
    include Apes::Model

    SECONDARY_KEY = :handle

    def self.table_name
      "querying_temp_table"
    end
  end

  class MockQueryingAnotherModel < MockBaseModel
    include Apes::Model

    def self.table_name
      "querying_temp_table"
    end
  end

  subject {
    MockQueryingModel.new(id: SecureRandom.uuid, handle: "HANDLE", name: "NAME")
  }

  around(:each) do |example|
    db = Tempfile.new("apes-test")
    MockBaseModel.establish_connection(adapter: "sqlite3", database: db.path)
    MockBaseModel.connection.execute("CREATE TABLE IF NOT EXISTS querying_temp_table(id uuid, handle varchar, name varchar);")
    example.call
    db.unlink
  end

  describe ".find_with_any!" do
    it "should find a record using the primary key when the ID is a UUID" do
      expect(MockQueryingOtherModel).to receive(:find).with(subject.id).and_return(subject)
      expect(MockQueryingOtherModel.find_with_any!(subject.id)).to eq(subject)
    end

    it "should find a record using the secondary key" do
      expect(MockQueryingOtherModel).to receive(:find_by!).with(handle: subject.handle).and_return(subject)
      expect(MockQueryingOtherModel.find_with_any!(subject.handle)).to eq(subject)
    end

    it "should find a record using the secondary query" do
      expect(MockQueryingModel).to receive(:find_by!).with("name = :id", {id: subject.name}).and_return(subject)
      expect(MockQueryingModel.find_with_any!(subject.name).id).to eq(subject.id)
    end

    it "should fallback to a reasonable query" do
      expect(MockQueryingAnotherModel).to receive(:find_by!).with(handle: subject.handle).and_return(subject)
      expect(MockQueryingAnotherModel.find_with_any!(subject.handle).id).to eq(subject.id)
    end

    it "should raise an exception when nothing is found" do
      expect { MockQueryingOtherModel.find_with_any!("NOTHING") }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe ".find_with_any" do
    it "should find a records" do
      expect(MockQueryingOtherModel).to receive(:find_by!).with(handle: subject.handle).and_return(subject)
      expect(MockQueryingOtherModel.find_with_any(subject.handle)).to eq(subject)
    end

    it "should raise an exception when nothing is found" do
      expect { MockQueryingOtherModel.find_with_any("NOTHING") }.not_to raise_error
    end
  end

  describe ".search" do
    let(:params) { {filter: {query: "ABC"}} }
    let(:table_name) { "querying_temp_table" }

    it "should do nothing if no value is present" do
      expect(MockQueryingOtherModel.search().to_sql).to eq("SELECT \"#{table_name}\".* FROM \"#{table_name}\"")
    end

    it "should perform a query on the fields" do
      expect(MockQueryingOtherModel.search(params: params, fields: [:name, :token, :secret]).to_sql).to eq("SELECT \"#{table_name}\".* FROM \"#{table_name}\" WHERE (name ILIKE '%ABC%' OR token ILIKE '%ABC%' OR secret ILIKE '%ABC%')")
    end

    it "should allow prefix based queries" do
      expect(MockQueryingOtherModel.search(params: params, start_only: true).to_sql).to eq("SELECT \"#{table_name}\".* FROM \"#{table_name}\" WHERE (name ILIKE 'ABC%')")
    end

    it "should allow case sensitive searches" do
      expect(MockQueryingOtherModel.search(params: params, case_sensitive: true).to_sql).to eq("SELECT \"#{table_name}\".* FROM \"#{table_name}\" WHERE (name LIKE '%ABC%')")
    end

    it "should allow to use AND based searches" do
      expect(MockQueryingOtherModel.search(params: params, method: :other).to_sql).to eq("SELECT \"#{table_name}\".* FROM \"#{table_name}\" WHERE (name ILIKE '%ABC%')")
    end

    it "should extend existing queries" do
      expect(MockQueryingOtherModel.search(params: params, query: MockQueryingOtherModel.where("secret IS NOT NULL")).to_sql).to eq("SELECT \"#{table_name}\".* FROM \"#{table_name}\" WHERE (secret IS NOT NULL) AND (name ILIKE '%ABC%')")
    end
  end

  describe "#additional_errors" do
    it "should return a ActiveModel::Errors object" do
      expect(MockQueryingModel.new.additional_errors).to be_a(ActiveModel::Errors)
    end
  end

  describe "#run_validations!" do
    it "should merge errors when validating" do
      subject = MockQueryingModel.new
      subject.additional_errors.add(:field, "ANOTHER")
      subject.validate
      expect(subject.errors.to_hash).to eq({field: ["ANOTHER", "can't be blank"]})
    end
  end

  describe "#all_validation_errors" do
    it "should allow to add additional errors after validation" do
      subject = MockQueryingModel.new
      expect(subject.all_validation_errors.to_hash).to eq({})
      subject.validate
      expect(subject.all_validation_errors.to_hash).to eq({field: ["can't be blank"]})
      subject.additional_errors.add(:field, "ANOTHER")
      expect(subject.all_validation_errors.to_hash).to eq({field: ["can't be blank", "ANOTHER"]})
      expect(subject.all_validation_errors.to_hash).to eq({field: ["can't be blank", "ANOTHER"]}) # Should not add errors twice
    end
  end
end