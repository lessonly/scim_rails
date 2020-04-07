Mime::Type.register "application/scim+json", :scim

ActionDispatch::ParamsParser::DEFAULT_PARSERS[Mime::Type.lookup('application/scim+json')] = lambda do |body|
  ActiveSupport::JSON.decode(body).with_indifferent_access
end
