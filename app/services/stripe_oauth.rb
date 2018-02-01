class StripeOauth < Struct.new(:user)
  def oauth_url(params)
    url = client.authorize_url({
      scope: 'read_write',
      stripe_landing:'register',
      stripe_user: {
        email: user.email
      }
    }.merge(params))

    begin
      response = RestClient.get url

    rescue => e
      json = JSON.parse(e.response.body) rescue nil
      if json && json['error']
        case json['error']

        when 'invalid_redirect_uri'
          return nil, <<-EOF
          Redirect URI is not setup correctly.
          Please see the <a href='#{Rails.configuration.github_url}/blob/master/README.markdown' target='_blank'>README</a>
          EOF

        else
          return [nil, params[:error_description]]

        end
      end

      return [nil, "Unable to connect to Stripe. #{e.message}"]
    end

    [url, nil]
  end

  def verify!(code)
    data = client.get_token(code, {
      headers: {
        'Authorization' => "Bearer #{Stripe.api_key}"
      }
    })

    user.stripe_user_id = data.params['stripe_user_id']
    user.stripe_account_type = 'oauth'
    user.publishable_key = data.params['stripe_publishable_key']
    user.secret_key = data.token
    user.currency = default_currency

    user.save!
  end

  def deauthorize!
    response = RestClient.post(
      'https://connect.stripe.com/oauth/deauthorize',
      { client_id: ENV['STRIPE_CONNECT_CLIENT_ID'], stripe_user_id: user.stripe_user_id }, {'Authorization' => "Bearer #{Stripe.api_key}"}
    )
    user_id = JSON.parse(response.body)['stripe_user_id']

    deauthorized if response.code == 200 && user_id == user.stripe_user_id
  end

  def deauthorized
    user.update_attributes(
      stripe_user_id: nil,
      secret_key: nil,
      publishable_key: nil,
      currency: nil,
      stripe_account_type: nil
    )
  end

  private

    def default_currency
      Stripe::Account.retrieve(user.stripe_user_id, user.secret_key).default_currency
    end

    def client
      @client ||= OAuth2::Client.new(
        Rails.configuration.stripe[:client_id],
        Stripe.api_key,
        {
          site: 'https://connect.stripe.com',
          authorize_url: '/oauth/authorize',
          token_url: '/oauth/token'
        }
      ).auth_code
    end
end
