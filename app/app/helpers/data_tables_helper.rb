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
end
