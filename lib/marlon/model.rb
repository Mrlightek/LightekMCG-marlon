require "active_model"

module Marlon
  class Model
    include ActiveModel::Model
    include ActiveModel::Attributes
    #Need to add a method that returns the models view scheme so external apps know how to build views for the model
  end
end
