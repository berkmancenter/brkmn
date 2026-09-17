# frozen_string_literal: true

require "rails_helper"

# rubocop:disable Metrics/BlockLength
RSpec.describe "Urls", type: :request do
  let(:user) { create(:user) }

  before do
    sign_in(user)
  end

  describe "POST /urls" do
    it "creates a URL for the signed-in user" do
      expect do
        post urls_path, params: {url: {to: "https://example.org/new-page", shortened: "new-page"}}
      end.to change(Url, :count).by(1)

      url = Url.last
      expect(url.user).to eq(user)
      expect(url.to).to eq("https://example.org/new-page")
      expect(url.shortened).to eq("new-page")
      expect(response).to redirect_to(urls_path)
    end

    it "redirects with an error without creating an invalid URL" do
      expect do
        post urls_path, params: {url: {to: "https://ex ample.org", shortened: "bad-url"}}
      end.not_to change(Url, :count)

      expect(flash[:error]).to include("must be a valid url")
      expect(response).to redirect_to(urls_path)
    end
  end

  describe "PATCH /urls/:id" do
    let(:url) { create(:url, user: user, to: "https://example.org/original") }

    it "updates the destination URL" do
      patch url_path(url), params: {url: {to: "https://example.org/updated"}}

      expect(response).to redirect_to(urls_path)
      expect(url.reload.to).to eq("https://example.org/updated")
      expect(url.last_edited_by).to eq(user)
      expect(url.last_edited_at).to be_present
    end

    it "renders the edit form and preserves the URL when the update is invalid" do
      patch url_path(url), params: {url: {to: "https://ex ample.org"}}

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("URL Details")
      expect(url.reload.to).to eq("https://example.org/original")
    end
  end

  describe "shared editing" do
    let(:url) { create(:url, user: user) }
    let(:collaborator) { create(:user) }

    it "lets an owner share edit access by email" do
      expect do
        post url_collaborators_path(url), params: {email: collaborator.email.upcase}
      end.to have_enqueued_mail(UrlCollaboratorMailer, :grant_notification)

      expect(response).to redirect_to(urls_path)
      expect(url.collaborators).to include(collaborator)
      expect(flash[:notice]).to include("can now edit")
    end

    it "does not email a user who already has edit access" do
      UrlCollaborator.create!(url: url, user: collaborator, granted_by: user)

      expect do
        post url_collaborators_path(url), params: {email: collaborator.email}
      end.not_to have_enqueued_mail(UrlCollaboratorMailer, :grant_notification)
    end

    it "renders sharing errors inside the affected link's modal" do
      post url_collaborators_path(url), params: {email: "missing@example.org"}
      follow_redirect!

      error_message = "No user was found with that email address."
      expect(response.body).to include(%(data-url-details-auto-open-value="true"))
      expect(response.body).to include(
        %(<div class="link_details__message link_details__message--error" role="alert">#{error_message}</div>)
      )
      expect(response.body.scan(error_message).length).to eq(1)
    end

    it "updates only the modal error region for Turbo requests" do
      post url_collaborators_path(url),
        params: {email: "missing@example.org"},
        headers: {"Accept" => "text/vnd.turbo-stream.html"}

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      expect(response.body).to include(%(action="replace" target="sharing_feedback_url_#{url.id}"))
      expect(response.body).to include(%(data-url-details-target="feedback"))
      expect(response.body).to include("No user was found with that email address.")
    end

    it "keeps the modal open and updates it after sharing with a Turbo request" do
      post url_collaborators_path(url),
        params: {email: collaborator.email},
        headers: {"Accept" => "text/vnd.turbo-stream.html"}

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      expect(response.body).to include(%(action="replace" target="sharing_feedback_url_#{url.id}"))
      expect(response.body).to include(%(action="replace" target="people_with_access_url_#{url.id}"))
      expect(response.body).to include("#{collaborator.email} can now edit this link.")
      expect(response.body).to include(%(role="status"))
      expect(url.reload.collaborators).to include(collaborator)
    end

    it "lets a collaborator edit and attributes the edit to them" do
      UrlCollaborator.create!(url: url, user: collaborator, granted_by: user)
      sign_in(collaborator)

      patch url_path(url), params: {url: {to: "https://example.org/shared-edit"}}

      expect(response).to redirect_to(urls_path)
      expect(url.reload.to).to eq("https://example.org/shared-edit")
      expect(url.last_edited_by).to eq(collaborator)
    end

    it "does not let a collaborator delete the link" do
      UrlCollaborator.create!(url: url, user: collaborator, granted_by: user)
      sign_in(collaborator)

      expect do
        delete url_path(url)
      end.to raise_error(CanCan::AccessDenied)
    end

    it "lets an owner remove edit access" do
      collaboration = UrlCollaborator.create!(url: url, user: collaborator, granted_by: user)

      expect do
        delete url_collaborator_path(url, collaboration)
      end.to have_enqueued_mail(UrlCollaboratorMailer, :removal_notification)

      expect(response).to redirect_to(urls_path)
      expect(url.reload.collaborators).not_to include(collaborator)
    end

    it "keeps the modal open and updates it after removing access with a Turbo request" do
      collaboration = UrlCollaborator.create!(url: url, user: collaborator, granted_by: user)

      delete url_collaborator_path(url, collaboration),
        headers: {"Accept" => "text/vnd.turbo-stream.html"}

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      expect(response.body).to include(%(action="replace" target="sharing_feedback_url_#{url.id}"))
      expect(response.body).to include(%(action="replace" target="people_with_access_url_#{url.id}"))
      expect(response.body).to include("Edit access was removed from #{collaborator.email}.")
      expect(response.body).to include(%(role="status"))
      expect(url.reload.collaborators).not_to include(collaborator)
    end

    it "does not let another user grant edit access" do
      sign_in(collaborator)

      expect do
        post url_collaborators_path(url), params: {email: create(:user).email}
      end.to raise_error(CanCan::AccessDenied)
    end
  end

  describe "access requests" do
    let(:url) { create(:url, user: user) }
    let(:requester) { create(:user) }

    it "allows another user to request edit access" do
      sign_in(requester)

      expect do
        post url_access_requests_path(url)
      end.to change(UrlAccessRequest, :count).by(1)
        .and have_enqueued_mail(UrlAccessRequestMailer, :owner_notification)

      expect(response).to redirect_to(urls_path)
      expect(UrlAccessRequest.last).to be_pending
    end

    it "does not email the owner again when the request is already pending" do
      UrlAccessRequest.create!(url: url, user: requester)
      sign_in(requester)

      expect do
        post url_access_requests_path(url)
      end.not_to have_enqueued_mail(UrlAccessRequestMailer, :owner_notification)
    end

    it "keeps the modal open and updates it after requesting access with Turbo" do
      sign_in(requester)

      post url_access_requests_path(url), headers: {"Accept" => "text/vnd.turbo-stream.html"}

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      expect(response.body).to include(%(action="replace" target="sharing_feedback_url_#{url.id}"))
      expect(response.body).to include(%(action="replace" target="access_request_footer_url_#{url.id}"))
      expect(response.body).to include("Your edit access request was sent to the link owner.")
      expect(response.body).to include("Edit access requested")
    end

    it "allows the owner to approve a request" do
      access_request = UrlAccessRequest.create!(url: url, user: requester)

      expect do
        patch url_access_request_path(url, access_request), params: {decision: "approve"}
      end.to have_enqueued_mail(UrlAccessRequestMailer, :approval_notification)

      expect(response).to redirect_to(urls_path)
      expect(access_request.reload).to be_approved
      expect(url.reload.collaborators).to include(requester)
    end

    it "allows the owner to deny a request" do
      access_request = UrlAccessRequest.create!(url: url, user: requester)

      expect do
        patch url_access_request_path(url, access_request), params: {decision: "deny"}
      end.to have_enqueued_mail(UrlAccessRequestMailer, :denial_notification)

      expect(response).to redirect_to(urls_path)
      expect(access_request.reload).to be_denied
      expect(url.reload.collaborators).not_to include(requester)
    end

    it "keeps the modal open and updates it after approving with Turbo" do
      access_request = UrlAccessRequest.create!(url: url, user: requester)

      patch url_access_request_path(url, access_request),
        params: {decision: "approve"},
        headers: {"Accept" => "text/vnd.turbo-stream.html"}

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(%(action="replace" target="sharing_feedback_url_#{url.id}"))
      expect(response.body).to include(%(action="replace" target="access_requests_url_#{url.id}"))
      expect(response.body).to include(%(action="replace" target="people_with_access_url_#{url.id}"))
      expect(response.body).to include("#{requester.email} can now edit this link.")
    end

    it "keeps the modal open and updates it after denying with Turbo" do
      access_request = UrlAccessRequest.create!(url: url, user: requester)

      patch url_access_request_path(url, access_request),
        params: {decision: "deny"},
        headers: {"Accept" => "text/vnd.turbo-stream.html"}

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(%(action="replace" target="sharing_feedback_url_#{url.id}"))
      expect(response.body).to include(%(action="replace" target="access_requests_url_#{url.id}"))
      expect(response.body).to include("The edit access request was denied.")
      expect(response.body).not_to include(%(target="people_with_access_url_#{url.id}"))
    end
  end

  describe "GET /urls" do
    it "renders owner, collaborator, and last-edit details in the sharing dialog" do
      url = create(:url, user: user)
      collaborator = create(:user)
      UrlCollaborator.create!(url: url, user: collaborator, granted_by: user)

      get urls_path

      expect(response.body).to include(%(Share "#{url.shortened}"))
      expect(response.body).to include(user.email)
      expect(response.body).to include(collaborator.email)
      expect(response.body).not_to include(collaborator.username)
      expect(response.body).to include("Last edit")
      expect(response.body).to include(%(data-url-details-details-url-value="#{details_url_path(url)}"))
    end
  end

  describe "GET /urls/:id/details" do
    it "renders the latest sharing dialog content" do
      url = create(:url, user: user)
      collaborator = create(:user)
      UrlCollaborator.create!(url: url, user: collaborator, granted_by: user)

      get details_url_path(url)

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/html")
      expect(response.body).to include(%(<dialog))
      expect(response.body).to include(collaborator.email)
      expect(response.body).to include("People with access")
    end
  end

  describe "GET /urls/:id/qr" do
    it "returns an inline PNG QR code for the short URL" do
      url = create(:url, user: user, shortened: "qr-code")

      get qr_url_path(url)

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("image/png")
      expect(response.headers["Content-Disposition"]).to include("inline")
      expect(response.body.bytes.first(8)).to eq([137, 80, 78, 71, 13, 10, 26, 10])
    end
  end
end
# rubocop:enable Metrics/BlockLength
