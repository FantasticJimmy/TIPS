class EstimateController < ApplicationController

  def index
    request.raw_post
  end
end