require 'money'

class EstimateController < ApplicationController
  include ApplicationHelper
  skip_before_filter :verify_authenticity_token
  def index
    from = request.parameters["from"]

    to = request.parameters["to"]
    from_date =request.parameters["from_date"]
    to_date =request.parameters["to_date"]
    currency_type =request.parameters["currency_type"]
    hotel_star_rating = request.parameters["hotel_preference"]["star_rating"]

    departure_info = get_the_flight_cost(from,to,from_date)

    hotel_info = get_the_hotel_cost(departure_info['arrival_city'],departure_info['arrival_date'],to_date,hotel_star_rating)

    car_rental_info = get_the_car_rental_cost(city:departure_info['arrival_city'],check_in_date:departure_info['arrival_date'].to_s,check_out_date:to_date,pick_up_drop_off_location:to)

    return_info = get_the_flight_cost(to,from,to_date)
    flight_hotel_cost = departure_info["cost"].to_f + return_info["cost"].to_f + hotel_info["total_hotel_cost"].to_f

    indexx = map_currency_code_to_country(departure_info["arrival_country"])
    cost_of_food = 50/(60.04) * indexx[:index] * (to_date.to_date - from_date.to_date - 1) 
    cost_of_car_rental = exchange_info(car_rental_info[:total_rental_expense]).fractional

    hotel_flight_food_car = cost_of_car_rental + cost_of_food + flight_hotel_cost

    local_food_expense = exchange_info(cost_of_food)

    response = {
                  currency_config:{currency_sigh: "$", currency_type: "CAD"},
                  hotel:{
                      name: hotel_info["hotel_name"], 
                      star_rating: hotel_info["hotelStarRating"],
                      review_rating: 4,
                      price: hotel_info["total_hotel_cost"]
                        },
                  flight:{
                    departure_agency:departure_info["airline_name"],
                    return_agency: departure_info["airline_name"],
                    review_rating: 4.5,
                    departure_price: departure_info["cost"],
                    return_price: return_info["cost"]
                  },
                  floating_daily_expense: cost_of_food,
                  car_rental: {
                    cost_of_car_rental:cost_of_car_rental,
                    car_model: car_rental_info[:car_model],
                    thumbnail_url: car_rental_info[:thumbnail_url]
                  },
                  total_expense: hotel_flight_food_car
                }
    render json: response
  end



end