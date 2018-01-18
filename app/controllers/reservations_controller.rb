class ReservationsController < ApplicationController
  def new
    @listing = Listing.find(params[:listing_id])
    @user = current_user

    @start_date = params[:reservation][:start_date]
    @end_date = params[:reservation][:end_date]
    @price_pernight = params[:reservation][:price_pernight]
    @total_price = params[:reservation][:total_price]
  end

  def index
    @reservations = current_user.reservations.where(self_booking: nil)
  end

  def reserved
    @listings = current_user.listings
  end

  def create
    @listing = Listing.find(params[:listing_id])

    if current_user == @listing.user
      selectedDates = params[:reservation][:selectedDates].split(",")

      reservationsByme = @listing.reservations.where(user_id: current_user.id)

      oldSelectedDates = []

      reservationsByme.each do |reservation|
        oldSelectedDates.push(reservation.start_date)
      end

      if oldSelectedDates
        oldSelectedDates.each do |date|
          @reservation = current_user.reservations.where(start_date:date, end_date:date)
          @reservation.destroy_all
        end
      end

      if selectedDates
        selectedDates.each do |date|
          current_user.reservations.create(listing_id: @listing.id, start_date: date, end_date: date, self_booking: true)
        end
      end

      redirect_back(fallback_location: root_path, notice: "更新できました")

    else

      user = @listing.user
      amount = params[:reservation][:total_price]
      fee = (amount.to_i * 0.1).to_i

      begin
        charge_attrs = {
          amount: amount,
          currency: user.currency,
          source: params[:token],
          description: "Test Charge via Stripe Connect",
          application_fee: fee
        }

        # charge_attrs[:destination] = user.stripe_user_id
        # charge = Stripe::Charge.create(charge_attrs)
        charge = Stripe::Charge.create(charge_attrs, user.secret_key)

        flash[:notice] = "Charged successfully!"

      rescue Stripe::CardError => e
        error = e.json_body[:error][:message]
        flash[:error] = "Charge failed! #{error}"
      end

      # 予約をパラメーター付与して作成
      @reservation = current_user.reservations.create(reservation_params)
      redirect_to @reservation.listing, notice: "予約が完了しました"

    end
  end

  def setdate
    listing = Listing.find(params[:listing_id])
    today = Date.today
    reservations = listing.reservations.where("start_date >= ? OR end_date >= ?",today,today)

    render json: reservations
  end

  def duplicate
    start_date = Date.parse(params[:start_date])
    end_date = Date.parse(params[:end_date])

    result = {
      duplicate: is_duplicate(start_date, end_date)
    }

    render json: result
  end

  private
    def reservation_params
      params.require(:reservation).permit(:start_date, :end_date, :price_pernight, :total_price, :listing_id)
    end

    def is_duplicate(start_date, end_date)
      listing = Listing.find(params[:listing_id])
      check = listing.reservations.where("? < start_date AND end_date < ?",start_date,end_date)
      check.size > 0 ? true : false
    end
end
