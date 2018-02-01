class PagesController < ApplicationController
  def index
    @users = User.all
  end

  def search
    if params[:search].present?

      session[:address] = params[:search]

      if params["lat"].present? & params["lng"].present?
        @latitude = params["lat"]
        @longitude = params["lng"]

        geolocation = [@latitude, @longitude]

      else
        geolocation = Geocoder.coordinates(params[:search])
        @latitude = geolocation[0]
        @longitude = geolocation[1]

      end
        @listings = Listing.where(active: true).near(geolocation, 3, order: 'distance')

    else
      @listings = Listing.where(active: true).all
      @latitude = @listings.to_a[0].latitude
      @longitude = @listings.to_a[0].longitude
    end



    # Ransack q のチェックボックス一覧
    if params[:q].present?

      if params[:q][:price_pernight_gteq].present?
        session[:price_pernight_gteq] = params[:q][:price_pernight_gteq]
      else
        session[:price_pernight_gteq] = nil
      end

      if params[:q][:price_pernight_lteq].present?
        session[:price_pernight_lteq] = params[:q][:price_pernight_lteq]
      else
        session[:price_pernight_lteq] = nil
      end

      if params[:q][:home_type_eq_any].present?
        session[:home_type_eq_any] = params[:q][:home_type_eq_any]

        session[:House] = session[:home_type_eq_any].include?("一軒家")
        session[:Mansion] = session[:home_type_eq_any].include?("マンション")
        session[:Apartment] = session[:home_type_eq_any].include?("アパート")
      else
        session[:home_type_eq_any] = ""
        session[:House] = false
        session[:Mansion] = false
        session[:Apartment] = false
      end

      if params[:q][:pet_type_eq].present?
        session[:pet_type_eq] = params[:q][:pet_type_eq]
      else
        session[:pet_type_eq] = nil
      end

      if params[:q][:breeding_years_gteq].present?
        session[:breeding_years_gteq] = params[:q][:breeding_years_gteq]
      else
        session[:breeding_years_gteq] = nil
      end

    end

    session[:q] = {
      "price_pernight_gteq" => session[:price_pernight_gteq],
      "price_pernight_lteq" => session[:price_pernight_lteq],
      "home_type_eq_any" => session[:home_type_eq_any],
      "pet_type_eq" => session[:pet_type_eq],
      "breeding_years_gteq" => session[:breeding_years_gteq]
    }

    @search = @listings.ransack(session[:q])
    @result = @search.result(distinct: true)
    @arrlistings = @result.to_a
    # @arrlistings = @listings.to_a





    if (!params[:start_date].blank? && !params[:end_date].blank?)

      session[:start_date] =params[:start_date]
      session[:end_date] =params[:end_date]

      start_date = Date.parse(session[:start_date])
      end_date = Date.parse(session[:end_date])

      @listings.each do |listing|

        unavailable = listing.reservations.where("(? <= start_date AND start_date <= ?) OR (? <= end_date AND end_date <= ?) OR (start_date < ? AND ? < end_date)", start_date, end_date, start_date, end_date,start_date, end_date).limit(1)


        if unavailable.length > 0
          @arrlistings.delete(listing)
        end
      end
    end
  end

  def ajaxsearch
    if !params[:geolocation].blank?
      geolocation = params[:geolocation]
    end

    if !params[:location].blank?
      session[:address] = params[:location]
    end


    @listings = Listing.where(active: true).near(geolocation, 5, order: 'distance')

    @arrlistings = @listings.to_a

    if ( !session[:start_date].blank? && !session[:end_date].blank? )

      start_date = Date.parse(session[:start_date])
      end_date = Date.parse(session[:end_date])

      @listings.each do |listing|
        unavailable = listing.reservations.where("(? <= start_date AND start_date <= ?) OR (? <= end_date AND end_date <= ?) OR (start_date < ? AND ? < end_date)", start_date, end_date, start_date, end_date, start_date, end_date).limit(1)

        if unavailable.length > 0
          @arrlistings.delete(listing)
        end
      end

    end

    respond_to :js
  end
end
