#
# This file is part of the apes gem. Copyright (C) 2016 and above Shogun <shogun@cowtech.it>.
# Licensed under the MIT license, which can be found at http://www.opensource.org/licenses/mit-license.php.
#

require "spec_helper"

describe Apes::Errors::BaseError do
  it "should save details" do
    subject = Apes::Errors::BaseError.new({a: 1})
    expect(subject.message).to eq("")
    expect(subject.details).to eq({a: 1})
  end
end
