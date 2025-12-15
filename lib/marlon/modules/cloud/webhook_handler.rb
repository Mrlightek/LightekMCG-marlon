# lib/marlon/modules/cloud/webhook_handler.rb
require "sinatra/base"
module Marlon::Modules::Cloud
  class WebhookHandler < Sinatra::Base
    post "/webhook/ci" do
      payload = JSON.parse(request.body.read)
      # Validate secret
      # Extract artifact_url, signature_url, tag
      artifact = payload["artifact_url"]
      sig = payload["signature_url"]
      tag = payload["tag"]
      # Register artifact, and schedule controlled rollout with default policy
      deployer = Deployer.new(OVHProvider.new(...), control_url: "https://control.lightek.com")
      # create a planned rollout or canary
      deployer.schedule_rollout(artifact_url: artifact, signature_url: sig, tag: tag, batch_size: 5, pause_s: 600)
      status 202
      { result: "scheduled", tag: tag }.to_json
    end
  end
end
