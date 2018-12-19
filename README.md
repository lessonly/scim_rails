# ScimRails

NOTE: This Gem is not yet fully SCIM complaint. It was developed with the main function of interfacing with Okta. There are features of SCIM that this Gem does not implement as described in the SCIM documentation or that have been left out completely.

#### What is SCIM?

SCIM stands for System for Cross-domain Identity Management. At its core, it is a set of rules defining how apps should interact for the purpose of creating, updating, and deprovisioning users. SCIM requests and responses can be sent in XML or JSON and this Gem uses JSON for ease of readabilty. 

To learn more about SCIM 2.0 you can read the documentation at [RFC 7643](https://tools.ietf.org/html/rfc7643) and [RFC 7644](https://tools.ietf.org/html/rfc7644).

The goal of the Gem is to offer a relatively painless way of adding SCIM 2.0 to your app. This Gem should be fully compatible with Okta's SCIM implementation. This project is ongoing and will hopefully be fully SCIM compliant in time. Pull requests that assist in meeting that goal are welcome!

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'scim_rails'
```

And then execute:

```bash
$ bundle
```

Or install it yourself as:

```bash
$ gem install scim_rails
```

Generate the config file with:

```bash
$ rails generate scim_rails config
```

The config file will be located at:

```
config/initializers/scim_rails_config.rb
```

Please update the config file with the models and attributes of your app.

Mount the gem in your routes file:

```ruby
Application.routes.draw do
  mount ScimRails::Engine => "/"
end
```

This will enable the following routes for the Gem to use:

| Request | Route               |
|:-------:|:-------------------:|
| get     | 'scim/v2/Users'     |
| post    | 'scim/v2/Users'     |
| get     | 'scim/v2/Users/:id' |
| put     | 'scim/v2/Users/:id' |
| patch   | 'scim/v2/Users/:id' |

Note: This Gem can be mounted to any path. For example:

```
https://scim.example.com/scim/v2/Users
https://www.example.com/scim/v2/Users
https://example.com/example/scim/v2/Users
```

## Usage

#### Content-Type

When sending requests to the server the `Content-Type` should be set to `application/scim+json` but will also respond to `application/json`.

All responses will be sent with a `Content-Type` of `application/scim+json, application/json`.

### List

##### All

Sample request:

```bash
$ curl -X GET 'http://username:password@localhost:3000/scim/v2/Users'
```

##### Pagination

This Gem provides two pagination filters; `startIndex` and `count`.

`startIndex` is the positional number you would like to start at. This parameter can accept any integer but anything less than 1 will be interpreted as 1. If you visualize an array with all your user records in the array, `startIndex` is basically what element you would like to start at. If you are familiar with SQL this parameter is directly correlated to the query offset. **The default value for this fitler is 1.**

`count` is the number of records you would like present in the response. **The default value for this filter is 100.**

Sample request:

```bash
$ curl -X GET 'http://username:password@localhost:3000/scim/v2/Users?startIndex=38&count=44'
```

Pagination only really works with a determinate order. What that means is, every time you call the database you need to get the results in the exact same order. So the 4th record is _always_ the 4th record and never appears in a different position. If there is no order then records might show up on multiple pages. **The default order is by id** but this can be configured with `scim_users_list_order`.

The pagination filters may be used on their own or in addition to the query filters listed in the next section.

##### Querying

Currently the only filter supported is a single level `eq`. More operators can be added failry easily in future releases. The SCIM RFC documents nested querying which is something we would like to implement in the future.

**Queryable attributes can be mapped in the configuration file.**

Supported filters:

```
filter=email eq test@example.com
fitler=userName eq test@example.com
filter=formattedName eq Test User
filter=id eq 1
```

Unsuppored filter:

```
filter=(email eq test@example.com) or (userName eq test@example.com)
```

Sample request:

```bash
$ curl -X GET 'http://username:password@localhost:3000/scim/v2/Users?filter=formattedName%20eq%20%22Test%20User%22'
```

### Show

This response can be modified in the configuration file. The `user_schema` configuration supports any JSON structure and will transform any values by calling symbols against the user model. A sample SCIM compliant response looks like:

```
{
  schemas: ["urn:ietf:params:scim:schemas:core:2.0:User"],
  id: "1",
  userName: "test@example.com",
  name: {
    givenName: "Test",
    familyName: "User"
  },
  emails: [
    {
      value: "test@example.com"
    },
  ],
  active: "true"
}
```

Sample request:

```bash
$ curl -X GET 'http://username:password@localhost:3000/scim/v2/Users/1'
```

### Create

The create request can receive any SCIM compliant JSON but can only be parsed with the configuration schema provided. What that means is that if your app receives a request to modify an attribute that is not listed in your `mutable_user_attributes` configuration it will ignore the parameter. In addition to needing to be included in the mutable attributes it also requires `mutable_user_attributes_schema` which defines where the Gem should look for a given attribute.

**Do not include attributes that you do not want modified** such as `id`. Any attributes can be provided in the `user_schema` configuration to be returned as part of the response but if they are not part of the `mutable_user_attributes_schema` then they cannot be modified.

Sample request:

```bash
$ curl -X POST 'http://username:password@localhost:3000/scim/v2/Users/' -d '{"schemas":["urn:ietf:params:scim:schemas:core:2.0:User"],"userName":"test@example.com","name":{"givenName":"Test","familyName":"User"},"emails":[{"primary":true,"value":"test@example.com","type":"work"}],"displayName":"Test User","active":true}' -H 'Content-Type: application/scim+json'
```

### Update

Update requests follow the same guidelines as create requests. The request is parsed for the mutable attributes provided in the configuration file and sent to the user model to update those attributes. This request expects a full representation of the object and any missing mutable attributes will send `nil` to the user model. If the attribute cannot be blank and sends a validation error, that error will be rescued and the response will be an appropriate SCIM error.

Sample request:

```bash
$ curl -X PUT 'http://username:password@localhost:3000/scim/v2/Users/1' -d '{"schemas":["urn:ietf:params:scim:schemas:core:2.0:User"],"userName":"test@example.com","name":{"givenName":"Test","familyName":"User"},"emails":[{"primary":true,"value":"test@example.com","type":"work"}],"displayName":"Test User","active":true}' -H 'Content-Type: application/scim+json'
```

### Deprovision

The PATCH request was implemented to work with Okta. Okta updates profiles with PUT and deprovisions with PATCH. This implemention of PATCH is not SCIM compliant as it does not update a single attribute on the user profile but instead only sends a deprovision request.

We would like to implement PATCH to be fully SCIM compliant in future releases.

Sample request:

```bash
$ curl -X PATCH 'http://username:password@localhost:3000/scim/v2/Users/1'
```

## Contributing

### [Code of Conduct](https://github.com/lessonly/scim_rails/blob/master/CODE_OF_CONDUCT.md)

### Pull Requests

Pull requests are welcome and encouraged! Please follow the default template format.

[How to create a pull request from a fork.](https://help.github.com/articles/creating-a-pull-request-from-a-fork/)

### Getting Started

Clone (or fork) the project.

Navigate to the top level of the project directory in your console and run `bundle install`.

Proceed to setting up the dummy app.

#### Dummy App

This Gem contains a fully functional Rails application that lives in `/spec/dummy`.

In the console, navigate to the dummy app at `/spec/dummy`.

Next run `bin/setup` to setup the app. This will set up the gems and build the databases. The databases are local to the project.

Last run `bundle exec rails server`.

If you wish you may send CURL requests to the dummy server or send requests to it via Postman.

### Specs

Specs can be run with `rspec` at the top level of the project (if you run `rspec` and it shows zero specs try running `rspec` from a different directory).

All specs should be passing. (The dummy app will need to be setup first.)

## License
The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
