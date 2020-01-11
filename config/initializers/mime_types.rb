
ActionDispatch::ParamsParser::DEFAULT_PARSERS[Mime::Type.lookup('application/scim+json')] = lambda do |body|
  ActiveSupport::JSON.decode(body)
end
