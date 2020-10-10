use Mix.Config

config :auth, Auth.Guardian,
  ttl: {1, :hour},
  grace: 600,
  issuer: "dein_apotheker"
