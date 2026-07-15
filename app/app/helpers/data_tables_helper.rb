module DataTablesHelper
  def data_table_url(table, params)
    query = params.to_query
    query.present? ? "#{table.path}?#{query}" : table.path
  end

  def data_table_sort_link(table, column)
    return column.header unless column.sortable?

    active = table.sort == column.key.to_s
    indicator = active ? (table.direction == "asc" ? "↑" : "↓") : nil
    label = safe_join([column.header, content_tag(:span, indicator, class: "sort-indicator")].compact, " ")

    link_to(
      label,
      data_table_url(table, table.sort_params(column)),
      class: class_names("sort-link", "active" => active),
      data: { turbo_frame: table.frame_id, turbo_action: "advance" }
    )
  end

  def data_table_page_numbers(table)
    pages = table.pagy.pages
    current_page = table.page
    first_page = [current_page - 2, 1].max
    last_page = [first_page + 4, pages].min
    first_page = [last_page - 4, 1].max

    (first_page..last_page).to_a
  end

  def data_table_pagination(table)
    return unless table.pagination?

    content_tag(:nav, class: "pagination", aria: { label: "Pagination" }) do
      safe_join(
        [
          data_table_previous_link(table),
          data_table_page_numbers(table).map { |page_number| data_table_page_link(table, page_number) },
          data_table_next_link(table)
        ].flatten
      )
    end
  end

  def data_table_previous_link(table)
    return disabled_pagination_link("Previous") unless table.pagy.previous

    link_to(
      "Previous",
      data_table_url(table, table.page_params(table.pagy.previous)),
      class: "pagination-link",
      data: { turbo_frame: table.frame_id, turbo_action: "advance" }
    )
  end

  def data_table_next_link(table)
    return disabled_pagination_link("Next") unless table.pagy.next

    link_to(
      "Next",
      data_table_url(table, table.page_params(table.pagy.next)),
      class: "pagination-link",
      data: { turbo_frame: table.frame_id, turbo_action: "advance" }
    )
  end

  def data_table_page_link(table, page_number)
    return content_tag(:span, page_number, class: "pagination-link current", aria: { current: "page" }) if page_number == table.page

    link_to(
      page_number,
      data_table_url(table, table.page_params(page_number)),
      class: "pagination-link",
      data: { turbo_frame: table.frame_id, turbo_action: "advance" }
    )
  end

  def disabled_pagination_link(label)
    content_tag(:span, label, class: "pagination-link disabled")
  end
end
