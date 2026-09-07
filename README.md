[![Gem Version](https://badge.fury.io/rb/paulie_lombardo.svg)](https://badge.fury.io/rb/paulie_lombardo)
[![CI](https://github.com/stadniklksndr/paulie_lombardo/actions/workflows/ci.yml/badge.svg)](https://github.com/stadniklksndr/paulie_lombardo/actions/workflows/ci.yml)

# Paulie Lombardo 🕵️‍♂️

> **A lightweight, ActiveRecord-only Ruby gem for tracking the count of page views in Rails applications.**
<br/>

🔍 **Looking for a simple Rails page view counter?**

If you are looking for an **impressionist alternative** or need to **track daily page views in Rails**, Paulie is built specifically for this job. Unlike heavy analytics engines or gems that require Redis/Memcached infrastructure, **PaulieLombardo is a simple Rails page view counter that relies purely on ActiveRecord** (PostgreSQL, MySQL, SQLite).

<br>

**Paulie** is the silent mobster standing at the entrance of your page. He sits by the door with a notebook, closely watching every visitor:

* 👤 **First visit?** Paulie writes it down.
* 🔄 **Came back a second time the same day?** Paulie gives a subtle nod and ignores it - no double counting.
* 🌅 **Returned the next day?** New day, new page in the notebook - Paulie logs a fresh visit when you ask him by passing the `interval: :daily` option!
<br>

## Default tracking behavior & Interval
By default, `PaulieLombardo` tracks unique views per request/session/user permanently. If a visitor with the same request/session/user inspects a page multiple times across different days, the view count **will not increase**. However, you can customize the tracking timeframe by passing the `interval` option.

#### Available options:
* `Default`: Permanent uniqueness per request_hash/session_hash/user_id. Repeated visits will not increment the counter, regardless of how much time passes.
* `interval: :daily`: Unique per calendar day (`:viewed_on`). Multiple visits on the same day count as 1 view, but visiting again the next day will add another view.
<br>

## Installation

Add this line to your application's Gemfile:

```ruby
gem "paulie_lombardo", "~> 1.0"
```

And then execute:

```bash
bundle install
```
<br>

## Quick start / Tracking page views in PostsController

Run the installer generator to create the database migration for `PaulieNote`:

```bash
rails generate paulie_lombardo:install posts
```

This generates two migration files:

* A migration to create the `paulie_notes` table.

* A migration to add the `:paulie_notes_count` counter cache column to the `posts` table.

**Note:** *The `:paulie_notes_count` column is required for any ActiveRecord model tracked by `has_paulie_notes`. You can pass multiple table names to add this column to several models at once (e.g., `rails generate paulie_lombardo:install posts questions etc`). You can omit table arguments only if you are tracking static pages exclusively.*

**Inside the Post Model (app/models/post.rb)**
```ruby
class Post < ApplicationRecord
  # If you need to use the interval option for unique views per calendar day,
  # replace the line below with: `has_paulie_notes interval: :daily`

  has_paulie_notes
end
```

**Tracking views in `PostsController` (app/controllers/posts_controller.rb)**

Simply call `paulie_note` inside your controller action:
```ruby
class PostsController < ApplicationController
  before_action :set_post, only: %i[ show edit update destroy ]

  # GET /posts/1 or /posts/1.json
  def show
    paulie_note(@post)
  end
end
```
**Displaying view counts in views (app/views/posts/show.html.erb)**
```erb
<article>
  <h2><%= @post.title %></h2>
  <span>Views: <%= @post.paulie_notes_count %></span>
</article>
```
<br>

## Tracking static pages (without ActiveRecord models)
`PaulieLombardo` allows you to track views for landing pages or any non-database static pages out of the box.

<br>

**In your controller (app/controllers/pages_controller.rb)**

Assign the result of `paulie_note` to an instance variable:
```ruby
class PagesController < ApplicationController
  def landing
    # If you need to use the interval option for unique views per calendar day,
    # replace the line below with: @page = paulie_note("landing", :daily)

    @page = paulie_note("landing")
  end
end
```

**In your view (app/views/pages/landing.html.erb)**

Use the `@page.paulie_notes_count` method to display the total number of views:
```erb
<h1>Welcome to our landing page</h1>
<p>Total views: <%= @page.paulie_notes_count %></p>
```
<br>

## Querying raw view data directly
If you need advanced analytics or custom reporting, you can query the underlying records directly using the `PaulieNote` model:

```ruby
# Fetch all views for a specific post
PaulieNote.where(noteable_type: "Post", noteable_id: "1")

# Fetch all views for a specific static page
PaulieNote.where(noteable_type: "PaulieStaticPage", noteable_id: "landing")

# Etc.

```

<br>

## User identification & Devise/Warden support
**PaulieLombardo** automatically tracks logged-in users if your application uses Warden (which powers Devise and many other Rails authentication solutions).

When a request is processed:

* **PaulieLombardo** checks request.env["warden"].

* If a user is authenticated, its `id` is saved into the `:user_id` column of the `paulie_notes` record.

* Once logged in, view uniqueness is tracked directly by `:user_id` across different sessions, devices, or browsers.
  
**Note:** *If Warden is not present or the user is a guest, **PaulieLombardo** gracefully falls back to browser session and request fingerprinting (session_hash / request_hash).*

<br>

## Bot & Crawler filtering

`PaulieLombardo` intentionally does not include internal bot-filtering logic to keep the gem fast and lightweight. Tracking and blocking bots inside controller actions is inefficient, as requests have already consumed application memory and CPU.

We recommend handling bot detection at the infrastructure layer (e.g., Cloudflare, Nginx) or via Rack Middleware such as [rack-attack](https://github.com/rack/rack-attack) before the request hits Rails controller logic.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/stadniklksndr/paulie_lombardo. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/stadniklksndr/paulie_lombardo/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the `paulie_lombardo` project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/stadniklksndr/paulie_lombardo/blob/master/CODE_OF_CONDUCT.md).
