module DataTable
  Filter = Struct.new(:key, :label, :field, :options, keyword_init: true) do
    def input_name(table_key)
      "#{table_key}[#{key}]"
    end

    def header
      label.presence || key.to_s.titleize
    end
  end
end
