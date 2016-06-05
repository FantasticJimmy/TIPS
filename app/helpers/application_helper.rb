require 'net/http'
module ApplicationHelper
  def expedia_API

  end

  def setup_conversion_rate
    url = URI.parse('http://query.yahooapis.com/v1/public/yql?q=select%20*%20from%20yahoo.finance.xchange%20where%20pair%20in%20(%22CADEUR%22,%20%22CADJPY%22,%20%22CADBGN%22,%20%22CADCZK%22,%20%22CADDKK%22,%20%22CADGBP%22,%20%22CADHUF%22,%20%22CADLTL%22,%20%22CADLVL%22,%20%22CADPLN%22,%20%22CADRON%22,%20%22CADSEK%22,%20%22CADCHF%22,%20%22CADNOK%22,%20%22CADHRK%22,%20%22CADRUB%22,%20%22CADTRY%22,%20%22CADAUD%22,%20%22CADBRL%22,%20%22CADCAD%22,%20%22CADCNY%22,%20%22CADHKD%22,%20%22CADIDR%22,%20%22CADILS%22,%20%22CADINR%22,%20%22CADKRW%22,%20%22CADMXN%22,%20%22CADMYR%22,%20%22CADNZD%22,%20%22CADPHP%22,%20%22CADSGD%22,%20%22CADTHB%22,%20%22CADZAR%22,%20%22CADISK%22)&env=store://datatables.org/alltableswithkeys')
    req = Net::HTTP::Get.new(url.to_s)
    res = Net::HTTP.start(url.host, url.port) {|http|
      http.request(req)
    }

    rates = Hash.from_xml(res.body)["query"]["results"]["rate"].inject({}) do |result, elem| 
      result[elem["Name"]] = elem["Rate"] 
      result 
    end
    rates = rates.each {|key,value| rates[key] = value.to_f}
  end

  def exchange_info(expense)
    rates = setup_conversion_rate
    rates.each do |key,value| 
      left, right = key.split('/')
      Money.add_rate(left,right, value)
    end
    Money.add_rate("CAD","USD",0.77)
    local_expense = Money.new(expense, "CAD").exchange_to("USD")  
  end

  def map_currency_code_to_country(country)
    case country.downcase
    when "cad"
      country_hash = {currency_code:"CAD",
      index: 60.04}
    when "usa"
      country_hash = {currency_code:"USD",
      index: 69.13}
    when "uk"
      country_hash = {currency_code:"GBP",
        index: 75.27}
    end

    # when "spain",
    #   "EUR"
    # when "germany",
    #   "EUR"
    #   60.68
    #   56.99
    # when "greece",
    #   "EUR"
    #   55.07
    # when "france",
    #   "EUR"
    #   73.48
    # when "italy",
    #   "EUR"
    # when "belgium"
    #   "EUR"
    #   82.87
    # when "japan"
    #   "JPY"
    #   47.45
    # when "bulgaria"
    #   "BGN"
    #   29.89
    # when "austria"
    #   "EUR"
    #   62.64
    # when "czech"
    #   "CZK"
    #   28.34
    # when "denmark"
    #   "DKK"
    #   97.88
    #   86.68
    # when "norway"
    #   "NOK"
    #   110.77
    # when "croatia"
    #   "HRK"
    #   37.57
    # when "russia"
    #   "RUB"
    #   42.05
    # when "turkey"
    #   "TRY"
    #   31.89
    # when "australia"
    #   "AUD"
    #   74.85
    # when "brazil"
    #   "BRL"
    #   31.55
    # when "china"
    #   "CNY"
    #   29.28
    # when "hongkong"
    #   "HKD"
    #   50.73
    # when "indonesia"
    #   "IDR"
    #   18.41 
    # when "israel"
    #   "ILS"
    #   77.27
    # when "india"
    #   "INR"
    #   15.31
    # when "korea"
    #   "KRW"
    #   41.18
    # when "mexico"
    #   "MXN"
    #   28.19
    # when "malaysia"
    #   "MYR"
    #   19.85
    # when "new zealand"
    #   "NZD"
    #   75.37
    # when "philippines"
    #   "PHP"
    #   18.59
    # when "singapore"
    #   "SGD"
    #   53.75 
    # when "thailand"
    #   "THB"
    #   20.22 
    # when "south africa"
    #   "ZAR"
    #   32.27 
    # when "iceland"
    #   "ISK"
    #   98.82
    
  end

  def get_the_flight_cost(from,to,from_date)
    url = URI.parse('http://terminal2.expedia.com/x/mflights/search?departureAirport=' + from + '&arrivalAirport=' + to + '&departureDate=' + from_date + '&adultAge=18&apikey='+ENV['expedia_API_KEY'])
    req = Net::HTTP::Get.new(url.to_s)
    res = Net::HTTP.start(url.host, url.port) {|http|
      http.request(req)
    }
    payload = ActiveSupport::JSON.decode(res.body)
    legId= payload["offers"].first['legIds']
    my_payload = {}
    my_payload["cost"] = payload["offers"].first.values_at('totalFare').first
    my_payload["arrival_date"]=payload["legs"].find{|x| x['legId']=legId}.values_at("segments").flatten.first['arrivalTime'].to_date
    my_payload["airline_name"]= payload["legs"].find{|x| x['legId']=legId}.values_at("segments").flatten.first['airlineName']
    my_payload["arrival_city"],my_payload['arrival_country'] = payload["legs"].find{|x| x['legId']=legId}.values_at("segments").flatten.last["arrivalAirportLocation"].split(", ")
    my_payload
  end


  def get_the_hotel_cost(city,check_in_date,check_out_date,star_rating)
    url = URI.parse('http://terminal2.expedia.com/x/mhotels/search?city=' + city + '&checkInDate=' + check_in_date.to_s + '&checkOutDate=' + check_out_date + '&verbose=0&room1=1&apikey='+ENV['expedia_API_KEY'])
    req = Net::HTTP::Get.new(url.to_s)
    res = Net::HTTP.start(url.host, url.port) {|http|
      http.request(req)
    }
    payload = ActiveSupport::JSON.decode(res.body)
    my_payload = {}

    filter_one = payload["hotelList"].select{|x|x["hotelStarRating"].to_f >= star_rating}.first

    my_payload["total_hotel_cost"] = filter_one.values_at('lowRateInfo').first["nightlyRatesPerRoom"].reduce(0){|memo,item|memo+=item["baseRate"].to_i}
    my_payload["hotel_name"]= filter_one["name"]
    my_payload
  end

  def get_the_car_rental_cost(city:city,check_in_date:check_in_date,check_out_date:check_out_date,pick_up_drop_off_location:pick_up_drop_off_location)
    url = URI.parse('http://terminal2.expedia.com/x/cars/search?pickupdate='+check_in_date+'&dropoffdate='+check_out_date+'&pickuplocation='+pick_up_drop_off_location+'&dropofflocation='+pick_up_drop_off_location+'&sort=price&limit=10&apikey='+ENV['expedia_API_KEY'])
    req = Net::HTTP::Get.new(url.to_s)
    res = Net::HTTP.start(url.host, url.port) {|http|
      http.request(req)
    }
    payload = ActiveSupport::JSON.decode(res.body)
    my_payload = {
      "car_model": payload["CarInfoList"]["CarInfo"].first["CarMakeModel"],
      "total_rental_expense": payload["CarInfoList"]["CarInfo"].first["Price"]["BaseRate"]["Value"],
      "url": payload["CarInfoList"]["CarInfo"].first["ThumbnailUrl"]
    }
    my_payload
  end

end
