require 'rails_helper'

RSpec.describe NotificationsController, type: :controller do
  describe "GET #index for reviews by session" do

    context "while user" do
      login_as :user

      it "should return forbidden" do
        get :index
        expect(response).to have_http_status(403)
      end
    end

    context "while admin" do
      login_as :admin

      let!(:track) { FactoryGirl.create :track }
      let!(:theme) { FactoryGirl.create :theme }
      let!(:first_session) { FactoryGirl.create :session_proposal, theme: theme, track: track }
      let!(:reviewer) { FactoryGirl.create(:reviewer, first_name: 'reviewer') }
      let!(:first_review) { FactoryGirl.create :review, session_proposal: first_session, user: reviewer, workflow_state: 'accepted' }
      let!(:second_review) { FactoryGirl.create :review, session_proposal: first_session, user: reviewer }
      let!(:second_session) { FactoryGirl.create :session_proposal, user: logged_in(:admin), theme: theme, track: track }
      let!(:third_review) { FactoryGirl.create :review, session_proposal: second_session, user: reviewer }

      it "should include reviews info" do
        get :index

        body = JSON.parse response.body
        expect(body['sessions'].count).to eq 2
        expect(body['sessions'].first['reviews'].count).to eq 2
        expect(body['sessions'].first['reviews'].first['reviewer']).to eq first_review.user.full_name
        expect(body['sessions'].first['reviews'].first['status']).to eq first_review.workflow_state
        expect(body['sessions'].last['reviews'].count).to eq 1
        expect(body['sessions'].last['reviews'].first['reviewer']).to eq third_review.user.full_name
        expect(body['sessions'].last['reviews'].first['status']).to eq third_review.workflow_state
      end

      it "should include session status" do
        second_session.accept!
        get :index

        body = JSON.parse response.body
        expect(body['sessions'].count).to eq 2
        expect(body['sessions'].first['status']).to eq first_session.workflow_state
        expect(body['sessions'].first['notified_on']).to be nil
        expect(body['sessions'].last['status']).to eq 'accepted'
      end
    end
  end
end
