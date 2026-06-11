module Api
  class CardsController < ApplicationController
    before_action :authenticate_user!

    # POST /api/cards/pay — pay down your credit card balance from a bank account.
    # Body: { from_account: "5021-0001", amount: 100.0 }
    #
    # The card that gets paid is always the signed-in customer's own card. The
    # funding account, however, is read from the request body so the UI can show
    # a "pay from" dropdown.
    #
    # VULNERABILITY 1 (Broken Access Control): `from_account` is trusted from the
    # request body and used to locate and debit a bank account with no check that
    # the account belongs to `current_user`. A customer can therefore pay off
    # their own credit card using someone else's money — e.g. sign in as Alice,
    # POST { from_account: "5021-0002", amount: 1000 } and Bob's account is
    # debited while Alice's card balance drops. The funding account should be
    # forced to `current_user[:account_number]`, exactly like transfers#create.
    def pay
      from_account = params[:from_account].to_s
      amount       = params[:amount].to_f

      return render json: { error: "Amount must be positive" }, status: :unprocessable_entity if amount <= 0

      card = current_user[:card]
      return render json: { error: "No credit card on file" }, status: :unprocessable_entity unless card

      source = Store.user_by_account(from_account)
      return render json: { error: "Funding account not found" }, status: :not_found unless source

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
