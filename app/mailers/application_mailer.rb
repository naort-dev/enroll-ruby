class ApplicationMailer < ActionMailer::Base

  default from: Settings.site.mail_address

  if Rails.env.production?
    self.delivery_method = :soa_mailer
  end

  def notice_email(notice)
    mail({ to: notice.to, subject: notice.subject}) do |format|
      format.html { notice.html }
    end
  end
end
