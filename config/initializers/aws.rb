Aws.config.update({
  access_key_id:     ENV['AWS_ACCESS_KEY_ID'],
  secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'] 
})
s3 = Aws::S3::Resource.new(region:'us-west-2')
S3_BUCKET = s3.bucket(ENV['S3_BUCKET'])