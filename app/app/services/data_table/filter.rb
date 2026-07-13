module DataTable
  Filter = Struct.new(:key, :label, :field, :options, :apply, keyword_init: true) do
    def input_name(table_key)
      "#{table_key}[#{key}]"
    end

    def header
      label.presence || key.to_s.titleize
    end

    def resolved_options(context = {})
      options.respond_to?(:call) ? options.call(context) : options
    end

    def apply_to(scope, value)
      return apply.call(scope, value) if apply

      scope.where(field => value)
    end
  end
end
