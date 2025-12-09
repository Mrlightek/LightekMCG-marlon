MARLON

The Official Ruby Framework of Lightek Media & Communications Group, Inc.

A Standalone, OS-Level, Reactive Service Framework

Fully proprietary. Fully Lightek.

No Rails. No Sinatra. No dependencies.

Just MARLON.

Machines
Actively
Routing
Lightek's
Orchestration
Network

🚀 What MARLON Is

Marlon is Lightek’s flagship Ruby application framework, purpose-built for:


✔ Telecom-scale services

✔ Systemd-native background workers

✔ High-performance reactive networking

✔ Gatekeeper-secured payload processing

✔ Server-driven UI for mobile clients

✔ Enterprise proxying & service routing

✔ Zero dependency on Rails or any other framework

Marlon is the foundation of the entire Lightek ecosystem.

This is our internal framework for:

Real-time VoIP

VR/AR app rendering

Media operations

Authentication

Routing

Distributed services

Thin-client mobile UI generation

🔥 Startup Flow

When any MARLON application boots:

Load config/marlon.yml

Load environment variables

Initialize ActiveRecord (optional, if enabled)

Load services

Load routers

Boot the MARLON Reactor

Start Falcon HTTP/WebSocket server

Load Reverse Proxy subsystem

Start systemd-managed background services

Begin dispatching requests into the Gatekeeper → Router → Service pipeline

Marlon apps run as first-class OS services, not "web apps."

🛰 Marlon Server Engine (“Lightek Reactor”)

Real features:

⚡ High-Performance Reactor

Based on Falcon fiber scheduler

No Rails middleware

Zero-blocking async pipeline

Multi-threaded & multi-worker support

🛰 Native WebSocket Core

Bi-directional messaging

Gateway integration

Reactive service channels

🔁 Industrial Reverse Proxy Layer

Load balancing

Failover

Circuit breakers

Rate limiting

Static asset caching

Header rewriting

URL rewriting

SSL termination

WebSocket pass-through

Hot reload proxy rules

🧩 Pluggable Middleware

Drop files in app/middleware/ — instantly active.

🔧 Configurable Worker Model

Forked workers

Thread pools

Async job runners

🛂 Gatekeeper Controller

The One Controller to Rule Them All.

Marlon has one and only one controller:

Gatekeeper

Everything—every request—passes through Gatekeeper:

Authentication

Permission validation

Payload verification

Token decryption

Signature validation

Rate enforcement

Payload → Router → Service dispatch

Response normalization

Acts as our API Gateway, our Security Boundary, and our App Router entrypoint.

🧭 Payload Router

The Payload Router transforms your JSON packets into service calls:

```json
POST /marlon/gatekeeper
{
  "service": "UserCreator",
  "action": "create",
  "payload": { ... }
}

```

Dispatches to:

```bash
services/user_creator.rb
```

Routers are miniature orchestrators:

```ruby
route "users.create", to: Services::UserCreator
route "profile.show", to: Services::ProfileShow
```

You can generate routers via:

```nginx
marlon g router AccountsRouter
```

📱 Marlon UI Schema

Server-Driven UI for Mobile & VR Clients

This is the Lightek secret weapon.

Your services now generate UI definitions:

```ruby
{
  ui: ui_schema do
    text "Welcome, #{user.name}"
    button "View Profile", action: "profile.show"
    list collection: @items do
      text :title
      text :subtitle
    end
  end
}
```

Devices (iOS, Flutter, VR, Web) receive:
Component tree
Layout
Actions
Forms
Styling/theme
Live reload capability
No need to update mobile apps when UI changes.
Marlon is the universal renderer.


🛠 Generators

Marlon comes with Rails-level generation power — but Marlon-native.

Core Generators

```cpp
marlon new my_app
marlon install
```

Service

```nginx
marlon g service UserCreator
```

Router

```nginx
marlon g router AccountsRouter
```

Gatekeeper

```nginx
marlon g gatekeeper
```

Scaffold

```sql
marlon g scaffold User
```

Creates:

Service

Router

Migration

Systemd unit (optional)

UI Schema file

Test suite

Migrations / Database

```sql
marlon g migration CreateUsers
marlon db:migrate
marlon db:rollback
```

Uses ActiveRecord internally if enabled.

Systemd

```css
marlon g systemd OrderProcessor
marlon systemd install OrderProcessor --force
```

Includes:

Unit file creation

Auto-copy to /etc/systemd/system

systemctl reload

systemctl enable/start

Reverse Proxy Rules

```nginx
marlon g proxy_rules
```

⚙ Runtime Commands

Just like Rails, but MARLON-native:

```pgsql
marlon start
marlon stop
marlon restart
marlon console
marlon logs
marlon routes
```

🛡 Deployment Model

Local Development

Runs without sudo.

Systemd units generated but not installed.

QA / Production

Systemd-managed everything

Blue/green deployments

Rolling restarts

Zero downtime reloads

Multi-worker Reactor cluster

Reverse proxy hot-reload

📦 Installation

Add to Gemfile:

```bash
bundle add marlon
```

Then:

```bash
marlon install
```

Or from RubyGems:

```bash
gem install marlon
```

⚡ Quickstart

```bash
mkdir my_app && cd my_app
bundle init
bundle add marlon
marlon install
marlon g service CreateUser
marlon server
```

🤝 Contributing

Private Lightek repo.

Issue tracking and contributions remain internal.

📜 License

MIT License.

🧭 Code of Conduct

Standard Lightek guidelines apply.
