export function pathForEvent(event) {
  switch (event.type) {
    case "dashboard":
      return "/dashboard";
    case "service-request-index":
    case "service-request-detail":
      return withQuery("/service_requests", event.params);
    case "site-index":
      return withQuery("/customer_sites", event.params);
    default:
      throw new Error(`No request path is registered for workflow type: ${event.type}`);
  }
}

export function withQuery(path, params = {}) {
  const entries = Object.entries(params).filter(([, value]) => value !== undefined && value !== null && value !== "");

  if (entries.length === 0) {
    return path;
  }

  const query = entries
    .map(([key, value]) => `${encodeURIComponent(key)}=${encodeURIComponent(String(value))}`)
    .join("&");

  return `${path}?${query}`;
}

export function firstServiceRequestPath(html) {
  const match = String(html).match(/href="(\/service_requests\/[0-9a-f-]+)"/);
  return match ? match[1] : null;
}
