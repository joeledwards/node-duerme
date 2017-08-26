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
$ duerme -v -s 404 -t 500 -T 2000 -u http://not.so
Config:
 { method: 'GET',
  payload: {},
  quiet: false,
  status: 404,
  connectTimeout: 500,
  totalTimeout: 2000,
  url: 'http://not.so',
  verbose: true }
Attempt 1 failed with status 200 (424.081 ms elapsed)
Attempt 2 failed with status 200 (886.383 ms elapsed)
Attempt 3 failed with status 200 (1.393 s elapsed)
Attempt 4 failed with status 200 (1.892 s elapsed)
Attempt 5 failed with status 200 (2.404 s elapsed)
All 5 attempts failed over 2.404 s
```

