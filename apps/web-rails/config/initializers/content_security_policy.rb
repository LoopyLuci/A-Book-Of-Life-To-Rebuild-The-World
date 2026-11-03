# Be sure to restart your server when you modify this file.
#
# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header
#
# The application renders plain HTML and CSS from the server. It ships no
# script at all, so the policy can stay strict.

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.font_src :self, :data
    policy.img_src :self, :data
    policy.object_src :none
    policy.script_src :self
    policy.style_src :self
    policy.form_action :self
    policy.frame_ancestors :none
    policy.base_uri :self
  end
end
