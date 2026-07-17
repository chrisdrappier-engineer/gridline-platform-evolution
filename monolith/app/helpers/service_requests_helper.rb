module ServiceRequestsHelper
  def service_request_table_headers(table)
    columns = table ? table.columns.map { |column| data_table_sort_link(table, column) } : default_service_request_table_headers
    safe_join(columns.map { |header| content_tag(:th, header) })
  end

  def default_service_request_table_headers
    ["Request", "Site", "Status", "Priority", "Dispatcher", "Reported"]
  end

  def service_request_dispatcher_cell(request)
    dispatcher = request.assigned_dispatcher
    return "Unassigned" unless dispatcher

    link_to dispatcher.name, dispatcher_path(dispatcher), class: "table-link"
  end

  def service_requests_empty_title(table)
    table&.empty_title || "No service requests yet"
  end

  def service_requests_empty_message(table)
    table&.empty_message || "Create the first request to start the dispatch workflow."
  end
end
