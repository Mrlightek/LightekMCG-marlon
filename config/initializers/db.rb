# config/initializers/db.rb
require_relative "../../lib/marlon/db"
require_relative "../../lib/marlon/db_adapter"

Marlon::DBAdapter.establish_connection # loads config from config/database.yml

# Run all migrations
require_relative "../../lib/marlon/migration_runner"
Marlon::MigrationRunner.run

# Now models are ready
user = User.new(name: "Marlon", email: "marlon@example.com", age: 30)
user.save
