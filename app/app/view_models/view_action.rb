ViewAction = Data.define(:label, :path, :style, :method) do
  def self.link(label, path, style: "secondary-button")
    new(label: label, path: path, style: style, method: nil)
  end

  def self.button(label, path, method:, style: "primary-button")
    new(label: label, path: path, style: style, method: method)
  end

  def button?
    method.present?
  end
end
