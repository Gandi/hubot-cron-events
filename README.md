Hubot Cron Events Plugin
=================================

[![Version](https://img.shields.io/npm/v/hubot-cron-events.svg)](https://www.npmjs.com/package/hubot-cron-events)
[![Downloads](https://img.shields.io/npm/dt/hubot-cron-events.svg)](https://www.npmjs.com/package/hubot-cron-events)
[![Build Status](https://img.shields.io/travis/Gandi/hubot-cron-events.svg)](https://travis-ci.org/Gandi/hubot-cron-events)
[![Dependency Status](https://gemnasium.com/Gandi/hubot-cron-events.svg)](https://gemnasium.com/Gandi/hubot-cron-events)
[![Coverage Status](http://img.shields.io/coveralls/Gandi/hubot-cron-events.svg)](https://coveralls.io/r/Gandi/hubot-cron-events)
[![Code Climate](https://img.shields.io/codeclimate/github/Gandi/hubot-cron-events.svg)](https://codeclimate.com/github/Gandi/hubot-cron-events)

This plugin is a generic event emitter scheduled using cron job. It's very similar to [hubot-cron](https://github.com/miyagawa/hubot-cron), but instead of sending messages it emits events.

By itself, this plugin is useless, but it's very handy when combined with other plugins that will receive the emitted events.



Installation
--------------
In your hubot directory:    

    npm install hubot-cron-events --save

Then add `hubot-cron-events` to `external-scripts.json`


Configuration
-----------------

If you use [hubot-auth](https://github.com/hubot-scripts/hubot-auth), the cron configuration commands will be restricted to user with the `admin` role. 

But if hubot-auth is not loaded, all users can access those commands.

It's also advised to use a brain persistence plugin, whatever it is, to persist the cron jobs between restarts.


Commands
--------------

Commands prefixed by `.cron` are here taking in account we use the `.` as hubot prefix, just replace it with your prefix if it is different.

    .cron version
        gives the version of the hubot-cron-events package loaded

    .cron <name> <period> [<tz>]
        will create or update a job with unique identifier <name>
        the <period> has to match a valid cronjob syntax of type * * * * *
        the optional <tz> has to match

    .cron list [<term>]

    .cron stop <name>
    .cron pause <name>

    .cron start <name>
    .cron resume <name>

    .cron delete <name>

    .cron <name> <key> <value>
    
    .cron <name> drop <key>


Testing
----------------

    npm install

    # will run make test and coffeelint
    npm test 
    
    # or
    make test
    
    # or, for watch-mode
    make test-w

    # or for more documentation-style output
    make test-spec

    # and to generate coverage
    make test-cov

    # and to run the lint
    make lint

    # run the lint and the coverage
    make

Changelog
---------------
All changes are listed in the [CHANGELOG](CHANGELOG.md)

Contribute
--------------
Feel free to open a PR if you find any bug, typo, want to improve documentation, or think about a new feature. 

Gandi loves Free and Open Source Software. This project is used internally at Gandi but external contributions are **very welcome**. 

Authors
------------
- [@mose](https://github.com/mose) - author and maintainer

License
-------------
This source code is available under [MIT license](LICENSE).

Copyright
-------------
Copyright (c) 2016 - Gandi - https://gandi.net
