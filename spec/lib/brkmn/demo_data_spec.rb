# frozen_string_literal: true

require "rails_helper"

# rubocop:disable Metrics/BlockLength
RSpec.describe Brkmn::DemoData do
  subject(:demo) { described_class.new(generated_links: 10) }

  let(:maya) { User.find_by!(email: "maya@demo.brkmn.test") }

  it "loads people, links, sharing and access requests" do
    demo.load!

    expect(demo.demo_users.count).to eq(8)
    expect(demo.demo_urls.count).to eq(32 + 10)
    expect(User.find_by!(email: "admin@demo.brkmn.test")).to be_superadmin
    expect(maya.valid_password?(described_class::DEFAULT_PASSWORD)).to be(true)
    expect(Url.find_by!(shortened: "lab-handbook").collaborators.map(&:email)).to eq(["jonas@demo.brkmn.test"])
    expect(UrlAccessRequest.pending.count).to eq(3)
    expect(Url.find_by!(shortened: "board-minutes").url_access_requests.first).to be_recently_denied
  end

  it "has users in every account state" do
    demo.load!

    expect(User.find_by!(email: "tom@demo.brkmn.test")).to be_access_locked
    expect(User.find_by!(email: "nora@demo.brkmn.test")).not_to be_confirmed
    expect(maya).to be_confirmed
  end

  it "keeps the destinations exactly as written" do
    demo.load!

    expect(Url.find_by!(shortened: "rsvp").to)
      .to eq("https://events.example.org/rsvp?event=fall-lecture&return=https://www.example.org/thanks")
    expect(Url.find_by!(shortened: "home").user).to be_nil
    generated = Url.find_by!(to: "https://scholar.google.com/scholar?q=platform+governance")
    expect(generated).to have_attributes(auto: true, shortened: match(/\A[A-Z]{6}\z/))
  end

  it "gives the same data on every run" do
    demo.load!
    first_run = Url.order(:shortened).pluck(:shortened, :to, :clicks)

    described_class.new(generated_links: 10).load!

    expect(Url.order(:shortened).pluck(:shortened, :to, :clicks)).to eq(first_run)
    expect(demo.demo_users.count).to eq(8)
  end

  it "puts the demo data back to its starting state when loaded again" do
    demo.load!
    url = Url.find_by!(shortened: "lab-handbook")
    url.update!(to: "https://changed.example.org")
    request = url.url_access_requests.find_by!(status: :pending)
    url.grant_edit_access_to(request.user, granted_by: maya)
    request.resolve!(:approved, by: maya)
    Url.create!(shortened: "made-while-playing", to: "https://example.org", user: maya)

    demo.load!

    expect(url.reload.to).to eq("https://docs.example.org/research-lab/handbook#onboarding")
    expect(url.url_access_requests.find_by!(user: request.user)).to be_pending
    expect(url.collaborators.map(&:email)).to eq(["jonas@demo.brkmn.test"])
    expect(Url.exists?(shortened: "made-while-playing")).to be(false)
  end

  it "never touches other data" do
    real_user = create(:user)
    real_link = create(:url, user: real_user, shortened: "home", to: "https://real.example.org")
    other_link = create(:url, user: real_user)

    demo.load!
    expect(demo.skipped_codes).to include("home")
    expect(real_link.reload.to).to eq("https://real.example.org")

    demo.remove!
    expect(User.all).to contain_exactly(real_user)
    expect(Url.all).to contain_exactly(real_link, other_link)
  end

  it "makes a bigger or smaller set of generated links" do
    described_class.new(generated_links: 25).load!
    expect(demo.demo_urls.count).to eq(32 + 25)

    demo.load!
    expect(demo.demo_urls.count).to eq(32 + 10)
  end

  it "reports the accounts and the password" do
    demo.load!

    expect(demo.report).to include("maya@demo.brkmn.test", described_class::DEFAULT_PASSWORD, "Things to try")
  end

  it "only loads in development and test unless allowed" do
    allow(Rails.env).to receive(:local?).and_return(false)

    expect { demo.load! }.to raise_error(described_class::NotAllowed)

    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("ALLOW_DEMO_DATA").and_return("true")
    expect { demo.load! }.not_to raise_error
  end
end
# rubocop:enable Metrics/BlockLength
