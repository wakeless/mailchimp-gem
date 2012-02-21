require 'action_mailer'

module Mailchimp
  class MandrillDeliveryHandler
    attr_accessor :settings

    def initialize options
      self.settings = {:use_api_key_from_mail_header => false, :track_opens => true, :track_clicks => true}.merge(options)
    end

    def deliver! message
      message_payload = {
        :track_opens => settings[:track_opens],
        :track_clicks => settings[:track_clicks],
        :message => {
          :subject => message.subject,
          :from_name => settings[:from_name],
          :from_email => message.from.first,
          :to_email => message.to
        }
      }

      mime_types = {
        :html => "text/html",
        :text => "text/plain"
      }

      get_content_for = lambda do |format|
        content = message.send(:"#{format}_part")
        content ||= message if message.content_type =~ %r{#{mime_types[format]}}
        content
      end

      [:html, :text].each do |format|
        content = get_content_for.call(format)
        message_payload[:message][format] = content.body if content
      end

      message_payload[:tags] = settings[:tags] if settings[:tags]
      
      if settings[:use_api_key_from_mail_header]
        Mandrill.new(message.api_key).send_email(message_payload)     
      else
        Mandrill.new(settings[:api_key]).send_email(message_payload)        
      end
    end

  end
end

ActionMailer::Base.add_delivery_method :mailchimp_mandrill, Mailchimp::MandrillDeliveryHandler
