ActionDispatch::Request.parameter_parsers[Mime::Type.lookup('application/scim+json').symbol] = lambda do |body|
  JSON.parse(body)
end
