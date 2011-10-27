require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

class TestModel < ActiveRecord::Base
  include Paperclip
  has_attached_file   :attachment,
                      :styles => { :large => '1000x1000>'},
                      :on_demand_styles => { :small => "600x600>" }
end

describe ThumbnailOnDemand do
  before(:each) do

  end
  describe "#thumbnail" do
    it "should return a string"
  end
end
