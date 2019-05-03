require "rails_helper"

RSpec.describe ProfilesController, type: :controller do
  context "spam update" do
    before :each do
      akismet_stub_response_spam
    end

    %i[sudara].each do |username|
      let(:user) { users(username) }

      before :each do
        login(username)
      end

      it "should flash a message and logout" do
        put :update, params: { user_id: username, profile: { bio: 'very spammy bio' } }
        expect(flash[:error]).to match (/magic fairies/)
        expect(response).to redirect_to(logout_path)
      end

      it "should mark user as spam if Akismet returns spam" do
        put :update, params: { user_id: username, profile: { bio: 'very spammy bio' } }
        expect(User.with_deleted.where(login: username).first.is_spam?).to eq(true)
      end

      it "should soft delete the user" do
        put :update, params: { user_id: username, profile: { bio: 'very spammy bio' } }
        expect(User.with_deleted.where(login: username).first.deleted?).to eq(true)
      end

      it "should soft delete user" do
        expect do
          put :update, params: { user_id: username, profile: { bio: 'very spammy bio' } }
        end.to change(User, :count).by(-1)
      end

      it "soft deletes assets" do
        asset_count = user.assets.count
        expect do
          put :update, params: { user_id: username, profile: { bio: 'very spammy bio' } }
        end.to change(Asset, :count).by(-asset_count)
      end

      it "soft deletes listens" do
        listen_count = user.listens.count + Listen.where(listener_id: user.id).count
        expect do
          put :update, params: { user_id: username, profile: { bio: 'very spammy bio' } }
        end.to change(Listen, :count).by(-listen_count)
      end

      it "soft deletes playlists" do
        playlist_count = user.playlists.count
        expect do
          put :update, params: { user_id: username, profile: { bio: 'very spammy bio' } }
        end.to change(Playlist, :count).by(-playlist_count)
      end

      it "soft deletes tracks" do
        track_count = user.assets.sum { |asset| asset.tracks.count }
        expect do
          put :update, params: { user_id: username, profile: { bio: 'very spammy bio' } }
        end.to change(Track, :count).by(-track_count)
      end

      it "soft deletes comments" do
        comments = user.assets.map { |asset| asset.comments }.flatten + user.comments
        comment_count = comments.uniq.length
        expect do
          put :update, params: { user_id: username, profile: { bio: 'very spammy bio' } }
        end.to change(Comment, :count).by(-comment_count)
      end

      it "soft deletes topics" do
        topic_count = user.topics.count
        expect do
          put :update, params: { user_id: username, profile: { bio: 'very spammy bio' } }
        end.to change(Topic, :count).by(-topic_count)
      end
    end
  end
end