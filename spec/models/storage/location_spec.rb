# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Storage::CloudFrontLocation, type: :model do
  let(:asset) do
    assets(:will_studd_rockfort_combalou)
  end
  let(:attachment) do
    asset.audio_file
  end

  it "does not initialize without signed argument" do
    expect do
      Storage::Location.new(attachment)
    end.to raise_error(ArgumentError)
  end

  it "does not initialize when attachment is nil" do
    expect do
      Storage::Location.new(nil, signed: false)
    end.to raise_error(ArgumentError)
  end

  it "coerces to string" do
    with_active_storage_host('alonetone.example.com') do
      expect(
        Storage::Location.new(attachment, signed: false).to_s
      ).to start_with('http://')
    end
  end

  context "using remote storage with CloudFront enabled" do
    around do |example|
      with_storage_service('s3') do
        with_alonetone_configuration(
          amazon_cloud_front_domain_name: 'xxxxxxxxxxxxxx.cloudfront.net',
          amazon_cloud_front_key_pair_id: 'XXXXXXXXXXXXXXXXXXXX',
          amazon_cloud_front_private_key: generate_amazon_cloud_front_private_key
        ) do
          example.call
        end
      end
    end

    it "generates a signed URL" do
      location = Storage::Location.new(attachment, signed: true)
      expect(location).to be_signed
      url = location.url
      expect(url).to include('cloudfront.net')
      expect(url).to include(attachment.key)
      uri = URI.parse(url)
      expect(uri.query).to_not be_nil
    end

    it "generates an unsiged URL" do
      location = Storage::Location.new(attachment, signed: false)
      expect(location).to_not be_signed
      url = location.url
      expect(url).to include('cloudfront.net')
      expect(url).to include(attachment.key)
      uri = URI.parse(url)
      expect(uri.query).to be_nil
    end
  end

  context "using remote storage" do
    around do |example|
      with_storage_service('s3') do
        with_alonetone_configuration(
          amazon_cloud_front_domain_name: nil,
          amazon_cloud_front_key_pair_id: nil,
          amazon_cloud_front_private_key: nil
        ) do
          example.call
        end
      end
    end

    it "generates a signed URL" do
      location = Storage::Location.new(attachment, signed: true)
      expect(location).to be_signed
      url = location.url
      expect(url).to include('amazonaws.com')
      expect(url).to include(attachment.key)
      uri = URI.parse(url)
      expect(uri.query).to_not be_nil
    end

    it "generates an unsiged URL" do
      location = Storage::Location.new(attachment, signed: false)
      expect(location).to_not be_signed
      url = location.url
      expect(url).to include('amazonaws.com')
      expect(url).to include(attachment.key)
      uri = URI.parse(url)
      expect(uri.query).to be_nil
    end
  end

  context "using local storage" do
    around do |example|
      with_storage_service('temporary') do
        with_alonetone_configuration(
          amazon_cloud_front_domain_name: nil,
          amazon_cloud_front_key_pair_id: nil,
          amazon_cloud_front_private_key: nil
        ) do
          with_active_storage_host(hostname) { example.call }
        end
      end
    end

    let(:hostname) { 'www.example.com' }

    it "generates a URL back to the application when signed" do
      location = Storage::Location.new(attachment, signed: true)
      url = location.url
      expect(url).to include(hostname)
    end

    it "generates a URL back to the application when unsigned" do
      location = Storage::Location.new(attachment, signed: false)
      url = location.url
      expect(url).to include(hostname)
    end
  end

  def with_active_storage_host(hostname)
    before = ActiveStorage::Current.host = 'www.example.com'
    begin
      ActiveStorage::Current.host = hostname
      yield
    ensure
      ActiveStorage::Current.host = before
    end
  end
end