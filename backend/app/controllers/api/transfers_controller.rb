module Api
  class TransfersController < ApplicationController
    before_action :authenticate_user!

    # POST /api/transfers — backs the "Transfer money" form on the dashboard.
    # Sends money from the signed-in customer's account to another account.
    # Body: { to_account: "5021-0003", amount: 150.0 }
    def create
      to_account = params[:to_account].to_s
      amount     = params[:amount].to_f

      return render json: { error: "Amount must be positive" }, status: :unprocessable_entity if amount <= 0

      # Source is the signed-in customer's own primary account.
      source         = Store.primary_account(current_user)
      source_number  = source[:number]

      found = Store.locate_account(to_account)
      return render json: { error: "Destination account not found" }, status: :not_found unless found

      destination      = found[:account]
      destination_user = found[:user]

      if to_account == source_number
        return render json: { error: "Cannot transfer to your own account" }, status: :unprocessable_entity
      end

      if amount > source[:balance]
        return render json: { error: "Insufficient funds" }, status: :unprocessable_entity
      end

      source[:balance]      = (source[:balance] - amount).round(2)
      destination[:balance] = (destination[:balance] + amount).round(2)

      Store.record_txn(source_number,
                       "Transfer to #{to_account} (#{destination_user[:name]})",
                       -amount, source[:balance])
      Store.record_txn(to_account,
                       "Transfer from #{source_number} (#{current_user[:name]})",
                       amount, destination[:balance])
      Store.log("INFO  txn  — transfer #{source_number} -> #{to_account} " \
                "amount=#{format('%.2f', amount)} status=ok")

      render json: { status: "ok", balance: source[:balance] }, status: :created
    end
  end
end
