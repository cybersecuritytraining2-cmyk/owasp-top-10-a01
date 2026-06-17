require "digest"
require "fileutils"

module Api
  class ExportsController < ApplicationController
    before_action :authenticate_user!

    # Generated CSV statements are written here and served back by #download.
    EXPORT_DIR = Rails.root.join("tmp", "exports")

    # POST /api/exports — backs the "Export CSV" button on the dashboard statement.
    # Writes a CSV of the account's statement and returns its download URL.
    # Body: { "account_number": "5021-0001" }
    def create
      account_number = params[:account_number].to_s
      found = Store.locate_account(account_number)
      return render json: { error: "Account not found" }, status: :not_found unless found

      FileUtils.mkdir_p(EXPORT_DIR)

      # Derive the export's filename.
      digest   = Digest::MD5.hexdigest("#{account_number}:#{Date.today}")
      filename = "statement-#{digest}.csv"

      rows = Store.transactions_for(account_number).map do |t|
        [ t[:created_at], csv_escape(t[:description]), t[:amount], t[:balance_after] ].join(",")
      end
      csv = ([ "date,description,amount,balance_after" ] + rows).join("\n") << "\n"
      File.write(EXPORT_DIR.join(filename), csv)

      Store.log("INFO  exp  — statement export account=#{account_number} " \
                "file=#{filename} user=#{current_user[:username]}")

      render json: {
        file:         filename,
        download_url: "/api/exports/#{filename}"
      }, status: :created
    end

    # GET /api/exports/*path — serves the file behind an export's download link.
    def download
      name = params[:path].to_s

      path = File.join(EXPORT_DIR, name)
      return render json: { error: "Export not found" }, status: :not_found unless File.file?(path)

      send_file path, type: "text/csv", disposition: "attachment", filename: File.basename(name)
    end

    private

    def csv_escape(value)
      str = value.to_s
      str.match?(/[",\n]/) ? %("#{str.gsub('"', '""')}") : str
    end
  end
end
