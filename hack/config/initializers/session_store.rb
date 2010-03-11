# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key    => '_mwrc_session',
  :secret => '993d1fdad76ed6768e55f62e43ffed3be8221e5e5db8a347b1546d07c7b539db93e165f74571f7e5b9656d608ad963f292172cb7f8f98087928f1afbc7350196'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
