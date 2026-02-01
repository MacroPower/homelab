const CONFIG = {
  githubOrg: "MacroPower",
  hosts: {
    "go.jacobcolvin.com": { type: "gomod" },
    "tap.jacobcolvin.com": { type: "repo", repo: "homebrew-tap" },
    "nur.jacobcolvin.com": { type: "repo", repo: "nur-packages" },
    "git.jacobcolvin.com": { type: "redirect" },
    "oci.jacobcolvin.com": { type: "oci" },
  },
};

// --- Helper Functions ---

/**
 * Checks if the request is a Go module discovery request.
 */
function isGoModuleRequest(url) {
  return url.searchParams.get("go-get") === "1";
}

/**
 * Checks if the request is from a git client.
 */
function isGitClientRequest(request) {
  const userAgent = request.headers.get("User-Agent") || "";
  return userAgent.toLowerCase().startsWith("git/");
}

/**
 * Builds the HTML response for Go module discovery.
 */
function buildGoModuleResponse(host, moduleName, githubOrg) {
  const importPath = `${host}/${moduleName}`;
  const repoUrl = `https://github.com/${githubOrg}/${moduleName}`;
  const pkgDevUrl = `https://pkg.go.dev/${importPath}`;

  const html = `<!DOCTYPE html>
<html>
<head>
  <meta name="go-import" content="${importPath} git ${repoUrl}">
  <meta name="go-source" content="${importPath} ${repoUrl} ${repoUrl}/tree/main{/dir} ${repoUrl}/blob/main{/dir}/{file}#L{line}">
  <meta http-equiv="refresh" content="0; url=${pkgDevUrl}">
</head>
<body>
  Redirecting to <a href="${pkgDevUrl}">documentation</a>...
</body>
</html>`;

  return new Response(html, {
    status: 200,
    headers: { "Content-Type": "text/html; charset=utf-8" },
  });
}

/**
 * Proxies a request to GitHub.
 */
async function proxyToGitHub(request, githubUrl) {
  const response = await fetch(githubUrl, {
    method: request.method,
    headers: request.headers,
    body: request.body,
    redirect: "follow",
  });

  return new Response(response.body, {
    status: response.status,
    headers: response.headers,
  });
}

// --- Type Handlers ---

/**
 * Extracts repo name and path from URL for multi-repo hosts.
 * Returns { repoName, repoPath } where repoName is the first path segment.
 */
function parseMultiRepoPath(url) {
  const path = url.pathname.replace(/^\//, "");
  const repoName = path.split("/")[0];
  const repoPath = url.pathname.slice(repoName.length + 1) || "";
  return { repoName, repoPath };
}

/**
 * Builds GitHub URL for a repo and path.
 */
function buildGitHubUrl(repoName, repoPath, search) {
  return `https://github.com/${CONFIG.githubOrg}/${repoName}${repoPath}${search}`;
}

const handlers = {
  /**
   * Go module discovery + git proxy.
   * - Returns go-import meta for ?go-get=1 requests
   * - Proxies git client requests
   * - Redirects browsers to GitHub
   * - Returns 404 for root path
   */
  gomod: async (request, url) => {
    const { repoName, repoPath } = parseMultiRepoPath(url);

    if (!repoName) {
      return new Response("Not Found", { status: 404 });
    }

    // Handle Go module discovery requests
    if (isGoModuleRequest(url)) {
      return buildGoModuleResponse(url.host, repoName, CONFIG.githubOrg);
    }

    const githubUrl = buildGitHubUrl(repoName, repoPath, url.search);

    // Proxy git client requests, redirect browsers
    if (isGitClientRequest(request)) {
      return proxyToGitHub(request, githubUrl);
    }

    return Response.redirect(githubUrl, 302);
  },

  /**
   * Browser/git redirect only.
   * - Redirects root to GitHub org page
   * - Redirects all requests to GitHub (never proxies)
   */
  redirect: async (request, url) => {
    const { repoName, repoPath } = parseMultiRepoPath(url);

    if (!repoName) {
      return Response.redirect(`https://github.com/${CONFIG.githubOrg}`, 302);
    }

    const githubUrl = buildGitHubUrl(repoName, repoPath, url.search);
    return Response.redirect(githubUrl, 302);
  },

  /**
   * Single repo redirect.
   * - All paths redirect to a single configured repo
   * - Never proxies, always redirects
   */
  repo: async (request, url, hostConfig) => {
    const repoName = hostConfig.repo;
    const repoPath = url.pathname;
    const githubUrl = buildGitHubUrl(repoName, repoPath, url.search);
    return Response.redirect(githubUrl, 302);
  },

  /**
   * OCI registry proxy for ghcr.io.
   * - Proxies /v2/ endpoints to ghcr.io with path rewriting
   * - Maps /v2/foo/... to ghcr.io/v2/macropower/foo/...
   * - Supports container images and Helm charts (both use OCI Distribution Spec)
   * - Read-only, public packages only
   */
  oci: async (request, url) => {
    // OCI Distribution Spec requires /v2/ prefix
    if (!url.pathname.startsWith("/v2/")) {
      return new Response("Not Found", { status: 404 });
    }

    // Build upstream URL with path rewriting
    let upstreamPath;
    if (url.pathname === "/v2/" || url.pathname === "/v2") {
      // Base endpoint - no rewriting needed
      upstreamPath = "/v2/";
    } else {
      // Rewrite: /v2/foo/... -> /v2/macropower/foo/...
      const pathAfterV2 = url.pathname.slice(4); // Remove "/v2/"
      upstreamPath = `/v2/${CONFIG.githubOrg.toLowerCase()}/${pathAfterV2}`;
    }

    const upstreamUrl = `https://ghcr.io${upstreamPath}${url.search}`;

    // Proxy the request to ghcr.io
    const upstreamResponse = await fetch(upstreamUrl, {
      method: request.method,
      headers: request.headers,
      body: request.body,
    });

    // Copy response headers, filtering Www-Authenticate if present
    const responseHeaders = new Headers(upstreamResponse.headers);
    const wwwAuth = responseHeaders.get("Www-Authenticate");
    if (wwwAuth) {
      // Rewrite realm to point to ghcr.io token endpoint (client needs to auth there)
      responseHeaders.set("Www-Authenticate", wwwAuth);
    }

    return new Response(upstreamResponse.body, {
      status: upstreamResponse.status,
      headers: responseHeaders,
    });
  },
};

// --- Main Handler ---

export default {
  async fetch(request) {
    const url = new URL(request.url);

    const hostConfig = CONFIG.hosts[url.host];
    if (!hostConfig) {
      return new Response("Not Found", { status: 404 });
    }

    const handler = handlers[hostConfig.type];
    if (!handler) {
      return new Response("Not Found", { status: 404 });
    }

    return handler(request, url, hostConfig);
  },
};
