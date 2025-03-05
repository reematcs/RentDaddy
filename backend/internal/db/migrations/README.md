# Using Migrations

When you make a change to a database schema, run the task command `make-migration -- <a-file-name>` to generate a new set of migration files.

In the `up.sql` file, place the new/updated sql script for the affected tables.
In `down.sql`, add the opposite. ie; if 'up' adds a table, 'down' removes said table if it exists.