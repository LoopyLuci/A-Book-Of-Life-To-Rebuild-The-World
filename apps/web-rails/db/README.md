# The database directory
#
# The knowledge base of *A Book Of Life To Rebuild The World* is read-only
# content that lives on disk, in `sidecars/` and `domains/`. It is loaded
# into memory at boot by `Corpus` (see `app/services/corpus.rb`) and it is
# never written to.
#
# For that reason **this application has no database**. There is no
# Active Record connection, no `config/database.yml`, and no migration to
# run. `rails db:prepare` is not needed, and the application boots and serves
# every page without one:
#
#     bin/rails server
#
# The preferences of the reader -- the interface language, the theme and the
# recently read entries -- are stored in cookies, not in a table.
#
# ## Adding a database later
#
# If a future version needs to store something (bookmarks for a signed-in
# reader, for example), add Active Record back:
#
#     bin/rails add_rails
#     bin/rails generate model Bookmark user:string entry_key:string
#     bin/rails db:prepare
#
# and point `config/database.yml` at a database. Nothing in the corpus layer
# depends on the database, so the read-only pages keep working unchanged.
