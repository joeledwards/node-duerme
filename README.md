¡Duerme!
===========

[![Build Status][travis-image]][travis-url]
[![NPM version][npm-image]][npm-url]

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

    -f, --connect-frequency <milliseconds>  Retry frequency (default is 1000)
    -m, --method <method>                   HTTP method (default is GET)
    -p, --payload <payload>                 JSON Payload (default is {})
    -q, --quiet                             Silence non-error output (default is false)
    -r, --regex <regex>                     Payload validation regex (default is undefined)
    -s, --status <status>                   Success status code (default is 200)
    -t, --connect-timeout <milliseconds>    Individual connection attempt timeout (default is 1000)
    -T, --total-timeout <milliseconds>      Total timeout across all connect attempts (dfault is 15000)
    -u, --url <url>                         URL (default is http://localhost:8080)
    -v, --verbose                           make output more verbose (default is false, superceded by -q option)
    -h, --help                              output usage information
```

Examples
============

```bash
Polling http://httpbin.org/status/200
✅  Attempt 1 succeeded. Time elapsed: 186.583 ms
```

```bash
$ duerme -t 250 -f 500 -T 2000 -u http://maybe.so
Polling http://maybe.so
⚠️  Attempt 1 failed (13.723 ms elapsed) : Error: getaddrinfo ENOTFOUND maybe.so maybe.so:80
remaining=485.919855 cap=1985.649866
⚠️  Attempt 2 failed (507.162 ms elapsed) : Error: getaddrinfo ENOTFOUND maybe.so maybe.so:80
remaining=496.825892 cap=1492.672962
⚠️  Attempt 3 failed (1.006 s elapsed) : Error: getaddrinfo ENOTFOUND maybe.so maybe.so:80
remaining=497.582397 cap=993.667252
⚠️  Attempt 4 failed (1.510 s elapsed) : Error: getaddrinfo ENOTFOUND maybe.so maybe.so:80
remaining=497.75541 cap=489.29356499999994
⚠️  Attempt 5 failed (2.002 s elapsed) : Error: getaddrinfo ENOTFOUND maybe.so maybe.so:80
❌  All 5 attempts failed over 2.002 s
```

```bash
$ duerme -v -s 301 -t 500 -T 2000 -u http://httpbin.org/status/404
Config:
            method : GET
               url : http://httpbin.org/status/404
           payload : {}
            status : 301
             regex : --
 connect frequency : 1.000 s
   connect timeout : 500.000 ms
     total timeout : 2.000 s
             quiet : false
           verbose : true
Polling http://httpbin.org/status/404
⚠️  Attempt 1 failed with status 404 (233.923 ms elapsed)
⚠️  Attempt 2 failed with status 404 (1.188 s elapsed)
⚠️  Attempt 3 failed with status 404 (2.158 s elapsed)
❌  All 3 attempts failed over 2.159 s
```

[travis-url]: https://travis-ci.org/joeledwards/node-duerme
[travis-image]: https://img.shields.io/travis/joeledwards/node-duerme/master.svg
[npm-url]: https://www.npmjs.com/package/duerme
[npm-image]: https://img.shields.io/npm/v/duerme.svg
