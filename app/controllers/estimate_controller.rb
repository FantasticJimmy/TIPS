require 'pry'
require 'money'

class EstimateController < ApplicationController
  include ApplicationHelper
  skip_before_filter :verify_authenticity_token
  def index
    from = request.parameters["estimate_request"]["from"]
    to = request.parameters["estimate_request"]["to"]
    from_date =request.parameters["estimate_request"]["from_date"]
    to_date =request.parameters["estimate_request"]["to_date"]
    currency_type =request.parameters["estimate_request"]["currency_type"]
    hotel_star_rating = request.parameters["estimate_request"]["hotel_preference"]["star_rating"]
    # rent_car = 

    departure_cost = get_the_flight_cost(from,to,from_date)
    return_cost = get_the_flight_cost(to,from,to_date)


    exchange_infoo = exchange_info
    render json: from
  end



end