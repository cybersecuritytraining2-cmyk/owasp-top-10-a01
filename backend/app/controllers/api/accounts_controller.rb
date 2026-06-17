require "erb"

module Api
  class AccountsController < ApplicationController
    before_action :authenticate_user!

    # GET /api/me — loads the dashboard: the signed-in customer's profile,
    # balance and card.
    def me
      render json: user_json(current_user)
    end

    # POST /api/accounts — backs the "Open a new account" form on the dashboard.
    # Creates an account for the signed-in customer and returns a welcome banner.
    # Body: { "label": "Vacation Fund" }
    def create
      attrs = params.permit!.to_h.symbolize_keys
                    .except(:controller, :action, :format, :account)

      account = {
        number:  Store.next_account_number,
        label:   "New Account",
        balance: 0.0
      }.merge(attrs)
      account[:balance] = account[:balance].to_f
      account[:label]   = account[:label].to_s

      current_user[:accounts] << account
      Store.log("INFO  acct — opened account=#{account[:number]} " \
                "label=#{account[:label]} balance=#{format('%.2f', account[:balance])} " \
                "user=#{current_user[:username]}")

      # Builds the welcome banner shown in the UI after the account is created.
      welcome = ERB.new(
        "Welcome to your new #{account[:label]} account, #{current_user[:name]}!"
      ).result(binding)

      render json: {
        account: {
          number:  account[:number],
          label:   account[:label],
          balance: account[:balance].round(2)
        },
        welcome: welcome
      }, status: :created
    end

    # GET /api/accounts/:account_number/transactions — backs the "Statement" view
    # on the dashboard. Returns the transaction history for the selected account.
    def transactions
      account_number = params[:account_number]
      account = current_user[:accounts].find { |a| a[:number] == account_number }
      return render json: { error: "Account not found" }, status: :not_found unless account

      render json: {
        account_number: account_number,
        holder:         current_user[:name],
        transactions:   Store.transactions_for(account_number)
      }
    end
  end
end
