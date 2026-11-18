# frozen_string_literal: true

require "rails_helper"

# rubocop:disable Metrics/BlockLength
RSpec.describe "Admin API tokens", type: :request do
  include ActiveJob::TestHelper

  let(:admin) { create(:user, :superadmin) }
  let(:invitation_params) do
    {
      external_api_token_invitation: {
        email: "partner@example.org",
        name: "Newsletter",
        note: "Weekly digest",
        access_level: "read_only",
        lifetime_days: "30"
      }
    }
  end

  context "as a regular user" do
    before { sign_in(create(:user)) }

    it "keeps them out" do
      get admin_api_tokens_path

      expect(response).to redirect_to(urls_path)
      expect(flash[:alert]).to include("Only superadmins")
    end

    it "doesn't let them create external users" do
      expect do
        post admin_api_tokens_path, params: invitation_params
      end.not_to change(User, :count)

      expect(response).to redirect_to(urls_path)
    end
  end

  context "as a superadmin" do
    before { sign_in(admin) }

    describe "GET /admin/api_tokens" do
      let!(:internal) { create(:api_token, name: "Internal CI", user: create(:user, email: "staff@example.org")) }
      let!(:external) do
        create(
          :api_token,
          name: "Partner feed",
          note: "Quarterly report",
          user: create(:user, email: "partner@example.net", api_only: true),
          created_by: admin
        )
      end
      let!(:revoked) { create(:api_token, :revoked, name: "Retired", revoked_by: admin) }

      it "lists every user's tokens" do
        get admin_api_tokens_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Internal CI", "Partner feed", "Retired", "External", "Quarterly report")
        expect(response.body).to include("by #{admin.username}")
        expect(response.body).to include(api_tokens_path, admin_api_tokens_path, new_admin_api_token_path)
        expect(response.body).to include("Settings", "All tokens", "External users", 'aria-current="page"')
      end

      it "filters by status" do
        get admin_api_tokens_path(status: "revoked")

        expect(response.body).to include("Retired")
        expect(response.body).not_to include("Internal CI", "Partner feed")
      end

      it "filters by user type" do
        get admin_api_tokens_path(kind: "external")

        expect(response.body).to include("Partner feed")
        expect(response.body).not_to include("Internal CI", "Retired")
      end

      it "searches email, name, note, and token prefix" do
        get admin_api_tokens_path(q: "STAFF@")
        expect(response.body).to include("Internal CI")
        expect(response.body).not_to include("Partner feed")

        get admin_api_tokens_path(q: "quarterly")
        expect(response.body).to include("Partner feed")

        get admin_api_tokens_path(q: external.token_prefix)
        expect(response.body).to include("Partner feed")
        expect(response.body).not_to include("Internal CI")
      end

      it "offers “Send new link” only for external users" do
        get admin_api_tokens_path

        expect(response.body).to include(reissue_admin_api_token_path(external))
        expect(response.body).not_to include(reissue_admin_api_token_path(internal))
      end
    end

    describe "GET /admin/api_tokens/new" do
      it "shows external-user creation as a settings tab" do
        get new_admin_api_token_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Settings", "External users", "Create a token for an external user")
        expect(response.body).to include(api_tokens_path, admin_api_tokens_path, 'aria-current="page"')
      end
    end

    describe "POST /admin/api_tokens" do
      it "creates an API-only user and queues an email with a claim link, never the token" do
        expect do
          post admin_api_tokens_path, params: invitation_params
        end.to change(User, :count).by(1).and have_enqueued_mail(ApiTokenMailer, :claim_instructions)

        user = User.find_by(email: "partner@example.org")
        token = user.api_tokens.sole
        perform_enqueued_jobs
        mail = ActionMailer::Base.deliveries.last

        expect(response).to redirect_to(admin_api_tokens_path)
        expect(flash[:notice]).to include("being emailed to partner@example.org")
        expect(user).to be_api_only
        expect(token).to have_attributes(created_by: admin, note: "Weekly digest", lifetime_days: 30)
        expect(token).to be_pending
        expect(mail.to).to eq(["partner@example.org"])
        expect(mail.body.encoded).to include(api_token_claim_url.split("?").first)
        expect(secrets_in(mail.body.encoded)).to be_empty
      end

      it "refuses an email that already has an account" do
        create(:user, email: "partner@example.org")

        expect do
          post admin_api_tokens_path, params: invitation_params
        end.not_to have_enqueued_mail(ApiTokenMailer, :claim_instructions)

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("already belongs to an account")
      end

      it "keeps the token and tells the admin when the email can't be queued" do
        message = instance_double(ActionMailer::MessageDelivery)
        allow(message).to receive(:deliver_later).and_raise(ActiveJob::EnqueueError, "Redis is down")
        mailer = double(claim_instructions: message)
        allow(ApiTokenMailer).to receive(:with).and_return(mailer)

        post admin_api_tokens_path, params: invitation_params

        expect(response).to redirect_to(admin_api_tokens_path)
        expect(flash[:alert]).to include("could not be queued", "Send new link")
        expect(User.find_by(email: "partner@example.org").api_tokens).to be_present
      end
    end

    describe "PATCH /admin/api_tokens/:id/revoke" do
      it "revokes anyone's token" do
        token = create(:api_token)

        patch revoke_admin_api_token_path(token)

        expect(response).to redirect_to(admin_api_tokens_path)
        expect(token.reload).to have_attributes(revoked_by: admin)
      end
    end

    describe "POST /admin/api_tokens/:id/reissue" do
      it "emails an external user a new link and stops the old token working" do
        secret = ApiToken.generate_secret
        token = create(:api_token, secret: secret, user: create(:user, api_only: true))

        expect do
          post reissue_admin_api_token_path(token)
        end.to have_enqueued_mail(ApiTokenMailer, :claim_instructions)

        expect(response).to redirect_to(admin_api_tokens_path)
        expect(flash[:notice]).to include("reissued")
        expect(ApiToken.find_for_secret(secret)).to be_nil
        expect(token.reload).to be_claimable
      end

      it "doesn't reissue internal users' tokens" do
        secret = ApiToken.generate_secret
        token = create(:api_token, secret: secret)

        expect do
          post reissue_admin_api_token_path(token)
        end.not_to have_enqueued_mail(ApiTokenMailer, :claim_instructions)

        expect(flash[:alert]).to include("Only external users")
        expect(ApiToken.find_for_secret(secret)).to eq(token)
      end

      it "doesn't reissue revoked tokens" do
        token = create(:api_token, :revoked, user: create(:user, api_only: true))

        expect do
          post reissue_admin_api_token_path(token)
        end.not_to have_enqueued_mail(ApiTokenMailer, :claim_instructions)

        expect(flash[:alert]).to include("revoked")
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
