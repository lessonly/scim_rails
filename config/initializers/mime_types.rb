Mime::Type.register "application/scim+json", :scimjson

ActionDispatch::Request.parameter_parsers[:scimjson] = lambda do |body|
  ActiveSupport::JSON.decode(body)
end
