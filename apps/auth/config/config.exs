use Mix.Config

config :auth, Auth.Guardian,
  ttl: {1, :hour},
  issuer: "dein_apotheker"
