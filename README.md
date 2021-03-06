# beekeeper-service

[![Dependency status](http://img.shields.io/david/octoblu/beekeeper-service.svg?style=flat)](https://david-dm.org/octoblu/beekeeper-service)
[![devDependency Status](http://img.shields.io/david/dev/octoblu/beekeeper-service.svg?style=flat)](https://david-dm.org/octoblu/beekeeper-service#info=devDependencies)
[![Build Status](http://img.shields.io/travis/octoblu/beekeeper-service.svg?style=flat)](https://travis-ci.org/octoblu/beekeeper-service)

[![NPM](https://nodei.co/npm/beekeeper-service.svg?style=flat)](https://npmjs.org/package/beekeeper-service)

# Table of Contents

* [Introduction](#introduction)
  * [What is Beekeeper](#what-is-beekeeper)
  * [Related Projects](#related-projects)
* [Getting Started](#getting-started)
  * [Install](#install)
  * [Start](#start)
  * [Run Tests](#run-tests)
  * [Docker](#docker)
* [License](#license)

# Introduction

## What is Beekeeper

Beekeeper is centralized deployment manager and tracking tool.

Works with [hub.docker.com](https://hub.docker.com), [codefresh.io](https://codefresh.io), and [travis-ci](https://travis-ci.org).

## Related Projects

* [beekeeper-util](https://gitub.com/octoblu/beekeeper-util)
* [beekeeper-worker](https://gitub.com/octoblu/beekeeper-worker)
* [beekeeper-updater-swarm](https://gitub.com/octoblu/beekeeper-updater-swarm)
* [beekeeper-updater-docker-compose](https://github.com/octoblu/beekeeper-updater-docker-compose)
* [beekeeper-updater-docker-stack](https://github.com/octoblu/beekeeper-updater-docker-stack)
* [gump](https://github.com/octoblu/unix-dev-tools-gump)

# Getting Started

## Install

```bash
git clone https://github.com/octoblu/beekeeper-service.git
cd /path/to/beekeeper-service
npm install
```

## Start

```javascript
yarn start
```

## Run Tests

```javascript
yarn test
```

## Docker

```bash
docker run --rm \
  --env 'MONGODB_URI=<mongodb-uri>' \
  --env 'REDIS_URI=<redis-uri>' \
  --env 'USERNAME=<beekeeper-username>' \
  --env 'PASSWORD=<beekeeper-password>' \
  octoblu/beekeeper-service
```

## License

The MIT License (MIT)

Copyright (c) 2016 Octoblu

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
