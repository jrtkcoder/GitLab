require 'rails_helper'

describe UploaderHelper do
  class ExampleUploader < CarrierWave::Uploader::Base
    include UploaderHelper

    storage :file
  end

  def upload_fixture(filename)
    fixture_file_upload(Rails.root.join('spec', 'fixtures', filename))
  end

  describe '#image_or_video?' do
    let(:uploader) { ExampleUploader.new }

    it 'returns true for an image file' do
      uploader.store!(upload_fixture('dk.png'))

      expect(uploader).to be_image_or_video
    end

    it 'it returns true for a video file' do
      uploader.store!(upload_fixture('video_sample.mp4'))

      expect(uploader).to be_image_or_video
    end

    it 'returns false for other extensions' do
      uploader.store!(upload_fixture('doc_sample.txt'))

      expect(uploader).not_to be_image_or_video
    end
  end
end
