use Mix.Config

config :auth, Auth.Guardian,
  issuer: "dein_apotheker",
  secret_key: "+ahrqH8Jv6KW/BvnDwj1sOM8f7xyICY8lQzu50AGpwvNyw5P+v40mI9Lwjz267CS"

config :guardian, Guardian,
  ttl: {1, :hour},
  allowed_drift: 2000
