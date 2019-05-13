require "rails_helper"

RSpec.describe Comment, type: :model do
  let(:new_comment) { assets(:valid_mp3).comments.new(body: 'test', commentable_type: 'Asset', commentable_id: '1') }

  describe 'scopes' do
    it 'include avatar image for comments and commenter to prevent n+1 queries' do
      expect do
        Comment.with_preloads.each do |comment|
          comment.commenter&.avatar_image
          if commentable = comment.commentable
            commentable.user.avatar_image
          end
        end
      end.to perform_queries(count: 7)
    end
  end

  context "validation" do
    it "should be valid when made by user" do
      expect(comments(:valid_comment_on_asset_by_user)).to be_valid
    end

    it "should be valid when made by guest" do
      expect(comments(:valid_comment_on_asset_by_guest)).to be_valid
    end

    it "should be valid even if spam" do
      expect(comments(:spam_comment_on_asset_by_guest)).to be_valid
    end

    it "should be able to be private as user" do
      expect(comments(:private_comment_on_asset_by_user)).to be_valid
    end

    it "should be able to be private as guest" do
      expect(comments(:private_comment_on_asset_by_guest)).to be_valid
    end
  end

  context "saving" do
    it "should store user_id when commenting on an asset" do
      expect(new_comment.save).to be_truthy
      expect(new_comment.user_id).to eq(assets(:valid_mp3).user_id)
    end

    it "should not save a dupe (same content/ip)" do
      body = comments(:valid_comment_on_asset_by_user).body
      ip = comments(:valid_comment_on_asset_by_user).remote_ip
      comment2 = Comment.new(body: body, remote_ip: ip, commentable_type: 'Asset', commentable_id: '1')
      expect(comment2.save).to be_falsey
    end
  end

  describe "soft deletion" do
    it "only soft deletes" do
      expect do
        Comment.all.map(&:soft_delete)
      end.not_to change { Comment.unscoped.count }
    end

    it "changes scope" do
      original_count = Comment.count
      expect do
        Comment.all.map(&:soft_delete)
      end.to change { Comment.count }.from(original_count).to(0)
    end
  end
end
