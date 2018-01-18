class StripeController < ApplicationController
  
  def oauth
    connector = StripeOauth.new(current_user)
    url, error = connector.oauth_url(redirect_uri: stripe_confirm_url)

    if url.nil?
      flash[:error] = error
      redirect_to manage_listing_bankaccount_path(session[:listing_id])
    else
      redirect_to url
    end
  end

  def confirm
    connector = StripeOauth.new(current_user)
    if params[:code]
      connector.verify!(params[:code])
    elsif params[:errors]
      flash[:error] = "Authorization request denied."
    end

    redirect_to manage_listing_bankaccount_path(session[:listing_id])
  end

  def deauthorize
    connector = StripeOauth.new(current_user)
    connector.deauthorize!
    flash[:notice] = "Account disconnected from Stripe"
    redirect_to manage_listing_bankaccount_path(session[:listing_id])
  end

end
