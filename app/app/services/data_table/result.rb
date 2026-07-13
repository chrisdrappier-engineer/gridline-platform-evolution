module DataTable
  Result = Struct.new(
    :key,
    :path,
    :columns,
    :filters,
    :rows,
    :pagy,
    :state,
    :page_size_options,
    :empty_title,
    :empty_message,
    keyword_init: true
  ) do
    def frame_id
      "#{key}_table"
    end

    def search
      state["search"].to_s
    end

    def sort
      state["sort"].to_s
    end

    def direction
      state["direction"] == "asc" ? "asc" : "desc"
    end

    def page
      pagy.page
    end

    def limit
      pagy.limit
    end

    def total_count
      pagy.count
    end

    def result_window
      return "0 results" if total_count.zero?

      "#{pagy.from}-#{pagy.to} of #{total_count}"
    end

    def pagination?
      pagy.pages > 1
    end

    def filter_value(filter)
      state[filter.key.to_s].to_s
    end

    def query_params(overrides = {})
      next_state = state.merge(stringify(overrides)).reject { |_key, value| value.blank? }
      { key => next_state }
    end

    def sort_params(column)
      next_direction = sort == column.key.to_s && direction == "asc" ? "desc" : "asc"
      query_params(sort: column.key, direction: next_direction, page: 1)
    end

    def page_params(page_number)
      query_params(page: page_number)
    end

    def clear_params
      {}
    end

    private

    def stringify(hash)
      hash.to_h.transform_keys(&:to_s)
    end
  end
end
