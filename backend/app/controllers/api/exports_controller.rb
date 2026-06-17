require "digest"
require "fileutils"

module Api
  class ExportsController < ApplicationController
    before_action :authenticate_user!

    # Generated CSV statements are written here and served back by #download.
    EXPORT_DIR = Rails.root.join("tmp", "exports")

    # POST /api/exports — generate a CSV export of an account's statement.
    # Body: { "account_number": "5021-0001" }
    #
    # VULNERABILITY 2 (Broken Access Control / IDOR): the account number is read
    # straight from the request body and used to generate a statement export with
    # NO check that the account belongs to `current_user`. The dashboard only ever
    # offers the customer's own accounts in the export dropdown, so the UI looks
    # safe — but the constraint lives only in the client. An attacker who
    # intercepts `POST /api/exports` (Burp/ZAP) and swaps `account_number` for
    # someone else's number — e.g. signed in as Alice, send
    # { "account_number": "5021-0002" } — gets a CSV of Bob's full statement back
    # via the returned download URL. Account numbers are short and sequential, so
    # they are trivial to enumerate. The export must be scoped server-side to one
    # of `current_user`'s own accounts, exactly like accounts#transactions does.
    def create
      account_number = params[:account_number].to_s
      found = Store.locate_account(account_number)
      return render json: { error: "Account not found" }, status: :not_found unless found

      FileUtils.mkdir_p(EXPORT_DIR)

      # VULNERABILITY 6 (Predictable resource name / insecure file identifier):
      # the export filename is derived only from the account number and today's
      # date. Wrapping it in MD5 makes it *look* random — a 32-char hex blob — but
      # it is fully deterministic. Account numbers are short and sequential
      # (5021-000N), so an attacker can recompute the exact filename for any
      # account on any day and pull another customer's already-generated export
      # from the download endpoint, which also performs no ownership check. The
      # name should be an unguessable random token (e.g. SecureRandom.uuid) bound
      # to the owner.
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

    # GET /api/exports/*path — download a previously generated export.
    def download
      name = params[:path].to_s

      # VULNERABILITY 7 (Path Traversal): the requested name is joined straight
      # onto the export directory with no sanitization or confinement check, so a
      # caller can climb out of tmp/exports using ../ sequences and read any file
      # the Rails process can access — e.g.
      #   GET /api/exports/..%2f..%2fconfig%2finitializers%2fstore.rb
      # leaks the seed file (hidden admin credentials and the API key). The fix is
      # to resolve the path and verify it is still inside EXPORT_DIR
      # (File.expand_path + start_with?) and to restrict the name to a known-safe
      # pattern such as /\Astatement-[0-9a-f]{32}\.csv\z/.
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
