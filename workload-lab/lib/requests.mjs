export function pathForEvent(event, workflowPaths) {
  const path = workflowPaths?.[event.type];

  if (!path) {
    throw new Error(`No request path is registered for workflow type: ${event.type}`);
  }

  return withQuery(path, event.params);
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

export function serviceRequestNotesPath(serviceRequestPath) {
  if (!/^\/service_requests\/[0-9a-f-]+$/.test(String(serviceRequestPath))) {
    throw new Error(`Invalid service request detail path: ${serviceRequestPath}`);
  }

  return `${serviceRequestPath}/service_request_notes`;
}
