module Api
  module Admin
    # Backs the Operations Console (the /admin screen in the SPA). Provides the
    # activity log, transaction, and user-management views.
    class DashboardController < ApplicationController
      before_action :authenticate_user!

      # GET /api/admin/logs — application log shown on the "logs" tab.
      def logs
        render json: { logs: Store::LOGS }
      end

      # GET /api/admin/transactions — ledger feed for the "transactions" tab.
      def transactions
        render json: { transactions: Store::TRANSACTIONS.sort_by { |t| t[:created_at] }.reverse }
      end

      # GET /api/admin/users — directory shown on the "users" tab.
      def users
        render json: {
          users: Store::USERS.values.map do |u|
            primary = Store.primary_account(u)
            {
              id:             u[:id],
              name:           u[:name],
              username:       u[:username],
              role:           u[:role],
              account_number: primary[:number],
              balance:        primary[:balance].round(2),
              blocked:        u[:blocked]
            }
          end
        }
      end

      # POST /api/admin/users/:id/block
      def block
        set_blocked(true)
      end

      # POST /api/admin/users/:id/unblock
      def unblock
        set_blocked(false)
      end

      private

      def set_blocked(value)
        user = Store::USERS[params[:id].to_i]
        return render json: { error: "User not found" }, status: :not_found unless user

        user[:blocked] = value
        Store.log("INFO  ops  — user=#{user[:username]} blocked=#{value} by=#{current_user[:username]}")
        render json: { id: user[:id], blocked: user[:blocked] }
      end
    end
  end
end
