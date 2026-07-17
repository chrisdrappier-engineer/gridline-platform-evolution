import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "message"]

  static values = {
    maxFiles: Number,
    maxTotalBytes: Number,
    imageBytes: Number,
    pdfBytes: Number,
    textBytes: Number
  }

  validate(event) {
    const error = this.validationError()

    if (error) {
      this.messageTarget.textContent = error
      this.inputTarget.value = ""
      event.preventDefault()
      return
    }

    this.messageTarget.textContent = ""
  }

  validationError() {
    const files = Array.from(this.inputTarget.files)
    const totalBytes = files.reduce((sum, file) => sum + file.size, 0)

    if (files.length > this.maxFilesValue) {
      return "Each note can include up to 5 files. Add another note if you need to upload more evidence."
    }

    if (totalBytes > this.maxTotalBytesValue) {
      return "Each note can include up to 15 MB of files. Add another note or reduce file sizes before uploading."
    }

    return files.map((file) => this.fileError(file)).find(Boolean)
  }

  fileError(file) {
    if (this.isImage(file)) {
      return file.size > this.imageBytesValue ? "Images must be 5 MB or smaller. Try exporting a smaller version or compressing the image before uploading." : null
    }

    if (this.isPdf(file)) {
      return file.size > this.pdfBytesValue ? "PDFs must be 10 MB or smaller. Try splitting the document into smaller PDFs or compressing the PDF before uploading." : null
    }

    if (this.isText(file)) {
      return file.size > this.textBytesValue ? "Text and CSV files must be 1 MB or smaller. Try splitting the file into smaller sections before uploading." : null
    }

    return "File type is not allowed. Upload images, PDFs, text files, or CSV files."
  }

  isImage(file) {
    return ["image/jpeg", "image/png", "image/webp"].includes(file.type)
  }

  isPdf(file) {
    return file.type === "application/pdf"
  }

  isText(file) {
    return ["text/plain", "text/csv", "application/csv"].includes(file.type) || file.name.match(/\.(txt|csv)$/i)
  }
}
