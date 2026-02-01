export default {
  async fetch(request) {
    const url = new URL(request.url);
    const githubUrl = `https://github.com/MacroPower${url.pathname}${url.search}`;

    const response = await fetch(githubUrl, {
      method: request.method,
      headers: request.headers,
      body: request.body,
      redirect: 'follow',
    });

    return new Response(response.body, {
      status: response.status,
      headers: response.headers,
    });
  }
}
