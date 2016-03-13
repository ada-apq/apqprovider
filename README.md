# APQ Provider

This a tiny package for handling multiple connections in
a sane way for your application.

This is useful in long-lived applications that require
a constant connection to the database. This module makes
sure you will always have a working connection when you
need it. Without the hassle of reconnecting multiple times.


It depends on two packages from KOW Framework:

* [KOW Lib](https://bitbucket.org/kowframework/kowlib)
* [KOW Config](https://bitbucket.org/kowframework/kowconfig)

And, of course, the core [apq](https://github.com/ada-apq/apq) plus
the specific driver you want to use.


This repository contains only the core functionality; specific
implementations are provided in the same way APQ implementations
are.

Notice, however, those packages are still on bitbucket:


* [APQProvider - ct\_lib](https://bitbucket.org/kowframework/apqprovider-ct_lib)
* [APQProvider - MySQL](https://bitbucket.org/kowframework/apqprovider-mysql)
* [APQProvider - PostgreSQL](https://bitbucket.org/kowframework/apqprovider-postgresql)
