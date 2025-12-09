# lib/marlon/model.rb
require "active_model"

module Marlon
  class Model
    include ActiveModel::Model
    include ActiveModel::Attributes
  end
end

