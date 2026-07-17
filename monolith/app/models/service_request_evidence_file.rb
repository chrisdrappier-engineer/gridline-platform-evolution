class ServiceRequestEvidenceFile < ApplicationRecord
  CATEGORIES = %w[
    site_photo
    before_photo
    after_photo
    invoice
    work_order
    diagnostic_report
    approval_document
    other
  ].freeze
  IMAGE_CONTENT_TYPES = %w[image/jpeg image/png image/webp].freeze
  PDF_CONTENT_TYPES = %w[application/pdf].freeze
  TEXT_CONTENT_TYPES = %w[text/plain text/csv application/csv].freeze
  ALLOWED_CONTENT_TYPES = (IMAGE_CONTENT_TYPES + PDF_CONTENT_TYPES + TEXT_CONTENT_TYPES).freeze
  MAX_IMAGE_SIZE = 5.megabytes
  MAX_PDF_SIZE = 10.megabytes
  MAX_TEXT_SIZE = 1.megabyte
  MAX_FILES_PER_NOTE = 5
  MAX_TOTAL_BYTES_PER_NOTE = 15.megabytes

  belongs_to :service_request_note
  belongs_to :uploaded_by, class_name: "User"

  has_one_attached :file

  validates :category, presence: true, inclusion: { in: CATEGORIES }
  validate :file_attached
  validate :allowed_content_type
  validate :allowed_file_size

  def self.category_options
    CATEGORIES.map { |category| [category.humanize, category] }
  end

  def self.accept_attribute
    ".jpg,.jpeg,.png,.webp,.pdf,.txt,.csv"
  end

  def self.limit_message_for(content_type)
    if IMAGE_CONTENT_TYPES.include?(content_type)
      "Images must be 5 MB or smaller. Try exporting a smaller version or compressing the image before uploading."
    elsif PDF_CONTENT_TYPES.include?(content_type)
      "PDFs must be 10 MB or smaller. Try splitting the document into smaller PDFs or compressing the PDF before uploading."
    elsif TEXT_CONTENT_TYPES.include?(content_type)
      "Text and CSV files must be 1 MB or smaller. Try splitting the file into smaller sections before uploading."
    else
      "File type is not allowed. Upload images, PDFs, text files, or CSV files."
    end
  end

  def image?
    file.attached? && IMAGE_CONTENT_TYPES.include?(file.content_type)
  end

  def filename
    file.filename.to_s
  end

  def byte_size
    file.byte_size
  end

  private

  def file_attached
    errors.add(:file, "must be attached") unless file.attached?
  end

  def allowed_content_type
    return unless file.attached?
    return if ALLOWED_CONTENT_TYPES.include?(file.content_type)

    errors.add(:file, self.class.limit_message_for(file.content_type))
  end

  def allowed_file_size
    return unless file.attached?
    return if file.byte_size <= max_size_for(file.content_type)

    errors.add(:file, self.class.limit_message_for(file.content_type))
  end

  def max_size_for(content_type)
    return MAX_IMAGE_SIZE if IMAGE_CONTENT_TYPES.include?(content_type)
    return MAX_PDF_SIZE if PDF_CONTENT_TYPES.include?(content_type)
    return MAX_TEXT_SIZE if TEXT_CONTENT_TYPES.include?(content_type)

    0
  end
end
