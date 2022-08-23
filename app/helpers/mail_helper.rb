module MailHelper
  # IMPORTANT!
  # Filmdb no longer utilizes sends to this email address. Code left for provenance.

  FROM_EMAIL = 'filmdb@indiana.edu'
  ADMIN_EMAIL = 'iulmia@indiana.edu'

  def notify_nitrate(physical_object)
    raise "Someone called notify nitrate - this has been deprecated and should no longer be in code!!!"
    # logger.debug "Sending nitrate base notification"
    # msg = "A physical object was marked as having a Nitrate base by #{physical_object.modifier.name}.\nBarcode: #{physical_object.iu_barcode}\nTitle: #{physical_object.titles_text}"
    # val = send_mail(ADMIN_EMAIL, 'Physical Object with Nitrate Base', msg)
    # logger.debug "Email sent? Return value: #{val}"
  end

  def test
    send_mail('jaalbrec@indiana.edu', "testing automated email", "this is only a test...")
  end

  private
  def send_mail(to_address, email_subject, email_body)
    Mail.deliver do
      from     FROM_EMAIL
      to       to_address
      subject  email_subject
      body     email_body
    end

  end
end