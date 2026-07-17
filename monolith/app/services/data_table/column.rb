module DataTable
  Column = Struct.new(:key, :label, :sortable_by, :searchable_by, keyword_init: true) do
    def header
      label.presence || key.to_s.titleize
    end

    def sortable?
      sortable_by.present?
    end

    def searchable_fields
      Array(searchable_by).compact
    end
  end
end
