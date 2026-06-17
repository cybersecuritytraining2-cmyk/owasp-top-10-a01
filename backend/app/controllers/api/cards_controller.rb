module Api
  class CardsController < ApplicationController
    before_action :authenticate_user!

    # POST /api/cards/pay — backs the "Pay your credit card" form on the dashboard.
    # Pays down the signed-in customer's card from a funding account.
    # Body: { from_account: "5021-0001", amount: 100.0 }
    def pay
      from_account = params[:from_account].to_s
      amount       = params[:amount].to_f

      return render json: { error: "Amount must be positive" }, status: :unprocessable_entity if amount <= 0

      card = current_user[:card]
      return render json: { error: "No credit card on file" }, status: :unprocessable_entity unless card

      found = Store.locate_account(from_account)
      return render json: { error: "Funding account not found" }, status: :not_found unless found

      source = found[:account]

      if amount > source[:balance]
        return render json: { error: "Insufficient funds in the funding account" }, status: :unprocessable_entity
      end

      pay_amount = [amount, card[:owed]].min

      source[:balance] = (source[:balance] - pay_amount).round(2)
      card[:owed]      = (card[:owed] - pay_amount).round(2)

      Store.record_txn(from_account,
                       "Credit card payment (card #{current_user[:card][:number][-4..]})",
                       -pay_amount, source[:balance])
      Store.log("INFO  card — payment account=#{from_account} " \
                "amount=#{format('%.2f', pay_amount)} status=ok")

      render json: { status: "ok", card_owed: card[:owed], funded_from: from_account }, status: :created
    end
  end
end
