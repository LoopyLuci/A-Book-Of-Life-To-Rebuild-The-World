# frozen_string_literal: true

Rails.application.routes.draw do
  # The home page: the sixteen domains of the knowledge base.
  root "home#index"

  # The domain index and one domain.
  get "domains", to: "domains#index", as: :domains
  get "domains/:slug", to: "domains#show", as: :domain

  # One entry.
  get "entries/:domain/:slug", to: "entries#show", as: :entry

  # The search page.
  get "search", to: "search#index", as: :search

  # The about page.
  get "about", to: "about#show", as: :about

  # The preferences of the reader.
  post "settings/language", to: "settings#language", as: :settings_language
  post "settings/theme", to: "settings#theme", as: :settings_theme

  # The files a search engine reads.
  get "robots.txt", to: "static#robots", as: :robots
  get "sitemap.xml", to: "static#sitemap", as: :sitemap

  # Reveal health status on /up that returns 200 if the app boots with no
  # exceptions, otherwise 500.
  get "up" => "rails/health#show", as: :rails_health_check
end
