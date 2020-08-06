# Upcoming Release

# v0.3.1 8-06-2020

- [Any unhandled error is now logged](https://github.com/lessonly/scim_rails/pull/27
) to the configured rails logger by default. You can also now supply a custom callable that will be used to handle those exceptions instead. 
- [Fix a bug](https://github.com/lessonly/scim_rails/pull/30) where an exception was raised when the patch endpoint receive a malformed or enexpected request.
