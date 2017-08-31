¡Duerme!
===========

Polls REST API routes until they match the required status or timeout.

Installation
============

```bash
$ npm i -g duerme
```

Usage
============

```bash
$ duerme --help

  Usage: duerme [options]


    Options:

      -m, --method <method>                 HTTP method (default is GET)
      -p, --payload <payload>               JSON Payload (default is {})
      -q, --quiet                           Silence non-error output (default is false)
      -s, --status <status>                 Success status code (default is 200)
      -t, --connect-timeout <milliseconds>  Individual connection attempt timeout (default is 250)
      -T, --total-timeout <milliseconds>    Total timeout across all connect attempts (dfault is 15000)
      -u, --url <url>                       URL (default is http://localhost:8080)
      -h, --help                            output usage information
```

Examples
============

```bash
$ duerme -u http://httpbin.org/status/200
Attempt 1 succeeded. Time elapsed: 456.596 ms
```

```bash
$ duerme -t 500 -T 2000 -u http://maybe.so
Attempt 1 failed (16.401 ms elapsed) : Error: getaddrinfo ENOTFOUND maybe.so maybe.so:80
Attempt 2 failed (509.165 ms elapsed) : Error: getaddrinfo ENOTFOUND maybe.so maybe.so:80
Attempt 3 failed (1.009 s elapsed) : Error: getaddrinfo ENOTFOUND maybe.so maybe.so:80
Attempt 4 failed (1.516 s elapsed) : Error: getaddrinfo ENOTFOUND maybe.so maybe.so:80
Attempt 5 failed (2.005 s elapsed) : Error: getaddrinfo ENOTFOUND maybe.so maybe.so:80
All 5 attempts failed over 2.005 s
```

```bash
$ duerme -v -s 301 -t 500 -T 2000 -u http://httpbin.org/status/404
Config:
 { method: 'GET',
  payload: {},
  quiet: false,
  status: 301,
  connectTimeout: 500,
  totalTimeout: 2000,
  url: 'http://httpbin.org/status/404',
  verbose: true }
Attempt 1 failed with status 404 (424.081 ms elapsed)
Attempt 2 failed with status 404 (886.383 ms elapsed)
Attempt 3 failed with status 404 (1.393 s elapsed)
Attempt 4 failed with status 404 (1.892 s elapsed)
Attempt 5 failed with status 404 (2.404 s elapsed)
All 5 attempts failed over 2.404 s
```

