module DataTable
  class Query
    DIRECTIONS = %w[asc desc].freeze

    def initialize(key:, path:, relation:, params:, columns:, filters:, default_sort:, page_size:, page_size_options:, paginator:,
                   empty_title:, empty_message:)
      @key = key.to_s
      @path = path
      @relation = relation
      @params = params.to_h.stringify_keys
      @columns = columns
      @filters = filters
      @default_sort = default_sort.stringify_keys
      @page_size = page_size
      @page_size_options = page_size_options
      @paginator = paginator
      @empty_title = empty_title
      @empty_message = empty_message
    end

    def call
      scoped_relation = apply_filters(apply_search(@relation))
      sorted_relation = apply_sort(scoped_relation)
      pagy, rows = paginate(sorted_relation)

      Result.new(
        key: @key,
        path: @path,
        columns: @columns,
        filters: @filters,
        rows: rows,
        pagy: pagy,
        state: state,
        page_size_options: @page_size_options,
        empty_title: @empty_title,
        empty_message: @empty_message
      )
    end

    private

    def apply_search(scope)
      return scope if search.blank?

      searchable_fields = @columns.flat_map(&:searchable_fields).uniq
      return scope if searchable_fields.empty?

      pattern = "%#{ActiveRecord::Base.sanitize_sql_like(search)}%"
      conditions = searchable_fields.map { |field| "#{field} ILIKE :search" }.join(" OR ")
      scope.where(conditions, search: pattern)
    end

    def apply_filters(scope)
      @filters.reduce(scope) do |current_scope, filter|
        value = @params[filter.key.to_s]
        value.present? ? current_scope.where(filter.field => value) : current_scope
      end
    end

    def apply_sort(scope)
      column = sortable_columns.fetch(sort_key) { sortable_columns.fetch(@default_sort.fetch("sort")) }
      direction_sql = direction.upcase

      scope.reorder(
        Arel.sql("#{column.sortable_by} #{direction_sql}"),
        Arel.sql("#{@relation.klass.table_name}.id ASC")
      )
    end

    def paginate(scope)
      pagy, rows = @paginator.call(scope, limit: limit, page: page)

      if pagy.count.positive? && pagy.page > pagy.pages
        pagy, rows = @paginator.call(scope, limit: limit, page: 1)
        @params["page"] = "1"
      end

      [pagy, rows]
    end

    def sortable_columns
      @sortable_columns ||= @columns.select(&:sortable?).index_by { |column| column.key.to_s }
    end

    def search
      @params["search"].to_s.strip
    end

    def sort_key
      key = @params["sort"].presence || @default_sort.fetch("sort")
      sortable_columns.key?(key) ? key : @default_sort.fetch("sort")
    end

    def direction
      value = @params["direction"].presence || @default_sort.fetch("direction")
      DIRECTIONS.include?(value) ? value : @default_sort.fetch("direction")
    end

    def page
      page_number = @params["page"].to_i
      page_number.positive? ? page_number : 1
    end

    def limit
      page_limit = @params["limit"].to_i
      @page_size_options.include?(page_limit) ? page_limit : @page_size
    end

    def state
      @params
        .merge("search" => search, "sort" => sort_key, "direction" => direction, "page" => page.to_s, "limit" => limit.to_s)
        .slice("search", "sort", "direction", "page", "limit", *@filters.map { |filter| filter.key.to_s })
    end
  end
end
