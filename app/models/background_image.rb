class BackgroundImage < ActiveRecord::Base
  attr_accessible :photo

  belongs_to :store

  if Rails.env.production?
    has_attached_file :photo,
                      :storage => :s3,
                      :path => ':attachment/:id/:style.:extension',
                      :s3_host_alias => 'd3633v0zz110qf.cloudfront.net',
                      :s3_credentials => {
                          :bucket => ENV['S3_BUCKET_NAME'],
                          :access_key_id => ENV['S3_ACCESS_KEY'],
                          :secret_access_key => ENV['S3_SECRET_KEY']
                      }
  else
    has_attached_file :photo
  end

  def photo_from_url(url)
    self.photo = open(url)
  end

end
