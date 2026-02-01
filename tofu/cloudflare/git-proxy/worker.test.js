import { describe, it, expect, beforeEach } from "vitest";
import worker from "./worker.js";

/**
 * Creates a mock Request object for testing.
 */
function createRequest(url, options = {}) {
  const { userAgent = "Mozilla/5.0", method = "GET" } = options;
  return new Request(url, {
    method,
    headers: {
      "User-Agent": userAgent,
    },
  });
}

describe("git-proxy worker", () => {
  describe("host configuration", () => {
    it("returns 404 for unconfigured hosts", async () => {
      const request = createRequest("https://unknown.example.com/repo");
      const response = await worker.fetch(request);

      expect(response.status).toBe(404);
      expect(await response.text()).toBe("Not Found");
    });

    it("returns 404 for empty repo name on multi-repo hosts", async () => {
      const request = createRequest("https://go.jacobcolvin.com/");
      const response = await worker.fetch(request);

      expect(response.status).toBe(404);
    });

    it("returns 404 for root path on go module hosts", async () => {
      const request = createRequest("https://go.jacobcolvin.com");
      const response = await worker.fetch(request);

      expect(response.status).toBe(404);
    });
  });

  describe("go module discovery (go.jacobcolvin.com)", () => {
    it("returns go-import HTML for ?go-get=1 requests", async () => {
      const request = createRequest(
        "https://go.jacobcolvin.com/mymodule?go-get=1"
      );
      const response = await worker.fetch(request);

      expect(response.status).toBe(200);
      expect(response.headers.get("Content-Type")).toBe(
        "text/html; charset=utf-8"
      );

      const html = await response.text();
      expect(html).toContain(
        '<meta name="go-import" content="go.jacobcolvin.com/mymodule git https://github.com/MacroPower/mymodule">'
      );
      expect(html).toContain('<meta name="go-source"');
      expect(html).toContain("pkg.go.dev/go.jacobcolvin.com/mymodule");
    });

    it("serves module root meta for subpackage requests", async () => {
      // When Go fetches go.jacobcolvin.com/mymodule/subpkg?go-get=1,
      // it needs to discover the module root (mymodule), not the subpackage
      const request = createRequest(
        "https://go.jacobcolvin.com/mymodule/subpkg?go-get=1"
      );
      const response = await worker.fetch(request);

      expect(response.status).toBe(200);
      const html = await response.text();

      // go-import must point to the module root, not the subpackage
      expect(html).toContain(
        '<meta name="go-import" content="go.jacobcolvin.com/mymodule git https://github.com/MacroPower/mymodule">'
      );
      // Should NOT include the subpackage path in the import
      expect(html).not.toContain("go.jacobcolvin.com/mymodule/subpkg git");
    });

    it("serves module root meta for deeply nested subpackages", async () => {
      // Deep paths like /foo/bar/baz/qux should still serve meta for /foo
      const request = createRequest(
        "https://go.jacobcolvin.com/mymodule/pkg/subpkg/internal/utils?go-get=1"
      );
      const response = await worker.fetch(request);

      expect(response.status).toBe(200);
      const html = await response.text();

      // go-import must point to the module root only
      expect(html).toContain(
        '<meta name="go-import" content="go.jacobcolvin.com/mymodule git https://github.com/MacroPower/mymodule">'
      );
      // pkg.go.dev redirect should also use the module root
      expect(html).toContain("pkg.go.dev/go.jacobcolvin.com/mymodule");
      expect(html).not.toContain("pkg.go.dev/go.jacobcolvin.com/mymodule/pkg");
    });

    it("redirects browser requests to GitHub", async () => {
      const request = createRequest("https://go.jacobcolvin.com/myrepo");
      const response = await worker.fetch(request);

      expect(response.status).toBe(302);
      expect(response.headers.get("Location")).toBe(
        "https://github.com/MacroPower/myrepo"
      );
    });

    it("redirects browser requests with subpaths to GitHub", async () => {
      const request = createRequest(
        "https://go.jacobcolvin.com/myrepo/tree/main/pkg"
      );
      const response = await worker.fetch(request);

      expect(response.status).toBe(302);
      expect(response.headers.get("Location")).toBe(
        "https://github.com/MacroPower/myrepo/tree/main/pkg"
      );
    });
  });

  describe("default repo mode (tap.jacobcolvin.com)", () => {
    it("uses defaultRepo for all requests", async () => {
      const request = createRequest("https://tap.jacobcolvin.com/Formula/app.rb");
      const response = await worker.fetch(request);

      expect(response.status).toBe(302);
      expect(response.headers.get("Location")).toBe(
        "https://github.com/MacroPower/homebrew-tap/Formula/app.rb"
      );
    });

    it("handles root path with defaultRepo", async () => {
      const request = createRequest("https://tap.jacobcolvin.com/");
      const response = await worker.fetch(request);

      expect(response.status).toBe(302);
      expect(response.headers.get("Location")).toBe(
        "https://github.com/MacroPower/homebrew-tap/"
      );
    });

    it("preserves query strings for defaultRepo hosts", async () => {
      const request = createRequest(
        "https://tap.jacobcolvin.com/blob/main/Formula/app.rb?raw=true"
      );
      const response = await worker.fetch(request);

      expect(response.status).toBe(302);
      expect(response.headers.get("Location")).toBe(
        "https://github.com/MacroPower/homebrew-tap/blob/main/Formula/app.rb?raw=true"
      );
    });
  });

  describe("nur repo mode (nur.jacobcolvin.com)", () => {
    it("redirects root path to nur-packages repo", async () => {
      const request = createRequest("https://nur.jacobcolvin.com/");
      const response = await worker.fetch(request);

      expect(response.status).toBe(302);
      expect(response.headers.get("Location")).toBe(
        "https://github.com/MacroPower/nur-packages/"
      );
    });

    it("redirects file paths to nur-packages repo", async () => {
      const request = createRequest("https://nur.jacobcolvin.com/flake.nix");
      const response = await worker.fetch(request);

      expect(response.status).toBe(302);
      expect(response.headers.get("Location")).toBe(
        "https://github.com/MacroPower/nur-packages/flake.nix"
      );
    });

    it("redirects nested paths to nur-packages repo", async () => {
      const request = createRequest(
        "https://nur.jacobcolvin.com/pkgs/mypackage/default.nix"
      );
      const response = await worker.fetch(request);

      expect(response.status).toBe(302);
      expect(response.headers.get("Location")).toBe(
        "https://github.com/MacroPower/nur-packages/pkgs/mypackage/default.nix"
      );
    });

    it("preserves query strings", async () => {
      const request = createRequest(
        "https://nur.jacobcolvin.com/blob/main/flake.nix?raw=true"
      );
      const response = await worker.fetch(request);

      expect(response.status).toBe(302);
      expect(response.headers.get("Location")).toBe(
        "https://github.com/MacroPower/nur-packages/blob/main/flake.nix?raw=true"
      );
    });
  });

  describe("redirect-only mode (git.jacobcolvin.com)", () => {
    it("redirects root path to GitHub org", async () => {
      const request = createRequest("https://git.jacobcolvin.com/");
      const response = await worker.fetch(request);

      expect(response.status).toBe(302);
      expect(response.headers.get("Location")).toBe(
        "https://github.com/MacroPower"
      );
    });

    it("redirects browser requests", async () => {
      const request = createRequest("https://git.jacobcolvin.com/myrepo");
      const response = await worker.fetch(request);

      expect(response.status).toBe(302);
      expect(response.headers.get("Location")).toBe(
        "https://github.com/MacroPower/myrepo"
      );
    });

    it("redirects git client requests (no proxy)", async () => {
      const request = createRequest("https://git.jacobcolvin.com/myrepo", {
        userAgent: "git/2.43.0",
      });
      const response = await worker.fetch(request);

      // redirectOnly hosts should redirect even for git clients
      expect(response.status).toBe(302);
      expect(response.headers.get("Location")).toBe(
        "https://github.com/MacroPower/myrepo"
      );
    });
  });

  describe("git client detection", () => {
    it("detects git client by User-Agent", async () => {
      const request = createRequest("https://go.jacobcolvin.com/myrepo", {
        userAgent: "git/2.43.0",
      });
      const response = await worker.fetch(request);

      // Git clients should be proxied (not redirected) for non-redirectOnly hosts
      // Since we can't actually proxy in tests, we just verify it doesn't redirect
      // The actual proxy would return whatever GitHub returns
      expect(response.status).not.toBe(302);
    });

    it("treats uppercase Git user-agent as git client", async () => {
      const request = createRequest("https://go.jacobcolvin.com/myrepo", {
        userAgent: "Git/2.43.0",
      });
      const response = await worker.fetch(request);

      // Should attempt to proxy (lowercase comparison)
      expect(response.status).not.toBe(302);
    });

    it("does not treat non-git user-agents as git clients", async () => {
      const request = createRequest("https://go.jacobcolvin.com/myrepo", {
        userAgent: "curl/8.0.0",
      });
      const response = await worker.fetch(request);

      expect(response.status).toBe(302);
    });
  });

  describe("security: path traversal prevention", () => {
    it("handles path traversal attempt with ..", async () => {
      const request = createRequest(
        "https://go.jacobcolvin.com/repo/../../../etc/passwd"
      );
      const response = await worker.fetch(request);

      // The URL constructor normalizes paths, so ../../../etc/passwd becomes /etc/passwd
      // This means repoName becomes "etc" and the path is "/passwd"
      // The key security check is that we never escape the GitHub org
      expect(response.status).toBe(302);
      const location = response.headers.get("Location");
      // Should still be within MacroPower org
      expect(location).toMatch(/^https:\/\/github\.com\/MacroPower\//);
      // Should NOT contain path traversal
      expect(location).not.toContain("..");
    });

    it("handles URL-encoded path traversal %2e%2e", async () => {
      const request = createRequest(
        "https://go.jacobcolvin.com/repo/%2e%2e/%2e%2e/secret"
      );
      const response = await worker.fetch(request);

      expect(response.status).toBe(302);
      const location = response.headers.get("Location");
      // URL decoding happens before we process, so .. should be normalized
      expect(location).toMatch(/^https:\/\/github\.com\/MacroPower\//);
    });

    it("handles double URL-encoded path traversal", async () => {
      const request = createRequest(
        "https://go.jacobcolvin.com/repo/%252e%252e/secret"
      );
      const response = await worker.fetch(request);

      expect(response.status).toBe(302);
      const location = response.headers.get("Location");
      // Double-encoded stays encoded (becomes %2e%2e in the path)
      expect(location).toMatch(/^https:\/\/github\.com\/MacroPower\//);
    });

    it("handles empty path segments", async () => {
      const request = createRequest(
        "https://go.jacobcolvin.com/repo//hidden//file"
      );
      const response = await worker.fetch(request);

      expect(response.status).toBe(302);
      const location = response.headers.get("Location");
      expect(location).toMatch(/^https:\/\/github\.com\/MacroPower\/repo/);
    });

    it("handles null bytes in path", async () => {
      const request = createRequest(
        "https://go.jacobcolvin.com/repo%00hidden"
      );
      const response = await worker.fetch(request);

      // Should handle gracefully without crashing
      expect([200, 302, 404]).toContain(response.status);
      if (response.status === 302) {
        const location = response.headers.get("Location");
        expect(location).toMatch(/^https:\/\/github\.com\/MacroPower\//);
      }
    });

    it("prevents accessing other GitHub orgs via path", async () => {
      const request = createRequest(
        "https://go.jacobcolvin.com/../../other-org/repo"
      );
      const response = await worker.fetch(request);

      expect(response.status).toBe(302);
      const location = response.headers.get("Location");
      // Path traversal should be normalized by URL, keeping us in MacroPower
      expect(location).toMatch(/^https:\/\/github\.com\/MacroPower\//);
    });
  });

  describe("query string handling", () => {
    it("preserves query strings in redirects", async () => {
      const request = createRequest(
        "https://go.jacobcolvin.com/repo?ref=v1.0.0"
      );
      const response = await worker.fetch(request);

      expect(response.status).toBe(302);
      expect(response.headers.get("Location")).toBe(
        "https://github.com/MacroPower/repo?ref=v1.0.0"
      );
    });

    it("handles multiple query parameters", async () => {
      const request = createRequest(
        "https://go.jacobcolvin.com/repo/blob/main/file.go?raw=true&token=abc"
      );
      const response = await worker.fetch(request);

      expect(response.status).toBe(302);
      expect(response.headers.get("Location")).toContain("raw=true");
      expect(response.headers.get("Location")).toContain("token=abc");
    });
  });
});
