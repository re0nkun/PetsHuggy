$(document).ready ->
  return unless StripeCheckout?

  submitting = false

  payButton = $('.pay-button')
  form = payButton.closest('form')
  indicator = form.find('.indicator').height( form.outerHeight() )
  handler =null

  createHandler = ->
    handler = StripeCheckout.configure
      key: window.publishable["platform"]
      email: window.currentUserEmail
      allowRememberMe: false

      closed: ->
        form.removeClass('processing') unless submitting

      token: ( token ) ->
        submitting = true
        form.find('input[name=token]').val( token.id )
        form.get(0).submit()
  createHandler()

  payButton.click ( e ) ->
    e.preventDefault()
    form.addClass( 'processing' )

    handler.open
      name: 'お支払い額'
      description: window.totalPrice + " 円"
      amount: ''
