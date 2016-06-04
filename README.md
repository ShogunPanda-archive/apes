# apes

[![Package Version](https://badge.fury.io/js/apes.png)](http://badge.fury.io/js/apes)
[![Dependency Status](https://gemnasium.com/ShogunPanda/apes.png?travis)](https://gemnasium.com/ShogunPanda/apes)
[![Build Status](https://secure.travis-ci.org/ShogunPanda/apes.png?branch=master)](http://travis-ci.org/ShogunPanda/apes)
[![Coverage Status](https://coveralls.io/repos/ShogunPanda/apes/badge.png)](https://coveralls.io/r/ShogunPanda/apes)

A tiny JSON API framework for Ruby on Rails.

https://sw.cowtech.it/apes

https://github.com/ShogunPanda/apes

# Introduction

Apes makes it easy to deal with [JSON API](http://jsonapi.org/) by abstracting all the oddities of the specification.

## Routes

There's no requirement at all here, but a good start point for your routes might be the following:

```ruby
Rails.application.routes.draw do
  # This is to enable AJAX cross domain
  match '*path', to: 'application#handle_cors', via: :options

  # Insert your routes here

  # Catch alls
  match("/*unused", via: :all, to: "application#error_handle_not_found")
  root(to: "application#error_handle_not_found")
end
```

## Controller

Once your controller inherits from `Apes::Controller`, you can implement a CRUD in virtually no time:

```ruby
class UsersController < Apes::Controller
  before_action :find_user, except: [:index, :create]

  def index
    @objects = paginate(User.all)
  end

  def show
  end

  def create
    @object = User.new
    attributes = request_extract_model(@object)
    @object.update_attributes!(request_cast_attributes(@object, attributes))

    response.header["Location"] = user_url(@object)
    response.status = :created
  end

  def update
    attributes = request_extract_model(@object)
    @object.update_attributes!(request_cast_attributes(@object, attributes))
  end

  def destroy
    @object.destroy!
    render(nothing: true, status: :no_content)
  end

  private

  def find_user
    @object = User.find(params[:id])
  end
end
```

By definining the `ATTRIBUTES` and `RELATIONSHIPS` in your model, you can ensure no invalid attributes are provided.

```
class Appointment < ApplicationRecord
  ATTRIBUTES = [:user, :assignee, :date, :reason].freeze
  RELATIONSHIPS = {user: nil, assignee: User}.freeze
end
```

## Model

If your model imports `Apes::Model`, it will earn two extra nice things: additional validations and enhanced search.

Additional validations use the same infrastructure of `ActiveModel::Validations` but it's not bound to any attribute and it's not reset when performing validations.

For instance, you can do:

```ruby
class User < ApplicationRecord
  include Apes::Model
end

u = User.new
u.additional_errors.add("whatever", "I don't like my name!")
u.validate!
p u.errors
p u.all_validation_errors
```

Enhanced searching, instead allow to perform single or multiple rows searching using `find_with_any` (including `find_with_any!` variant) or `search`.

The latter will perform full text search on one or more fields returning all matching rows:

```ruby
ZipCode.search(params: params, query: collection, fields: ["zip", "name", "county", "state"])
```

The former instead, with perform a exact search basing on the model definition and returning the first matching row:

```ruby
ZipCode.find_with_any!(params[:id])
```

You can customize which fields is searching on by defining the constants `SECONDARY_KEY` or `SECONDARY_QUERY` in your model.

Note that UUID are always matched against the `id` column.

## View

There's nothing much to say here. `Apes::Controller` handles views and error rendering.

All you need to do is to define a partial view in `app/views/models` using JBuilder.
If your action defines `@objects` or `@object` variables, Apes will render a collection or a single object automagically.

Example (`app/views/models/_appointment.json.jbuilder`):

```ruby
json.type "appointment"
json.id object.to_param

json.attributes do
  json.extract! object, :date, :reason
end

json.relationships do
  included = local_assigns.fetch(:included, false)

  json.assignee do
    json.data({type: "user", id: object.assignee.to_param})
    json.links({related: user_url(object.assignee)})
    response_included(object.assignee) unless included
  end
  
  json.user do
    json.data({type: "user", id: object.user.to_param})
    json.links({related: user_url(object.user)})
    response_included(object.user) unless included
  end
end

json.links do
  json.self appointment_url(object)
end

json.meta(meta) if local_assigns.key?(:meta)
```

## Contributing to apes

* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet.
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it.
* Fork the project.
* Start a feature/bugfix branch.
* Commit and push until you are happy with your contribution.
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.

## Copyright

Copyright (C) 2016 and above Shogun <shogun@cowtech.it>.

Licensed under the MIT license, which can be found at http://opensource.org/licenses/MIT.
