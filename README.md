Hubot Cron Events Plugin
=================================

[![Version](https://img.shields.io/npm/v/hubot-cron-events.svg)](https://www.npmjs.com/package/hubot-cron-events)
[![Downloads](https://img.shields.io/npm/dt/hubot-cron-events.svg)](https://www.npmjs.com/package/hubot-cron-events)
[![Build Status](https://img.shields.io/travis/Gandi/hubot-cron-events.svg)](https://travis-ci.org/Gandi/hubot-cron-events)
[![Dependency Status](https://gemnasium.com/Gandi/hubot-cron-events.svg)](https://gemnasium.com/Gandi/hubot-cron-events)
[![Coverage Status](https://img.shields.io/codeclimate/coverage/github/Gandi/hubot-cron-events.svg)](https://codeclimate.com/github/Gandi/hubot-cron-events/coverage)
[![Code Climate](https://img.shields.io/codeclimate/github/Gandi/hubot-cron-events.svg)](https://codeclimate.com/github/Gandi/hubot-cron-events)

This plugin is a generic event emitter scheduled using cron job. It's very similar to [hubot-cron](https://github.com/miyagawa/hubot-cron), but instead of sending messages it emits events.

This plugin can be very handy when combined with other plugins that will receive the emitted events.

There is another similar plugin named [hubot-at-events](https://github.com/Gandi/hubot-at-events) that applies the same principle for one-time actions at given dates.

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

    .cron <name> <period> <eventname>
    .cron <name> <period> <eventname> <tz>
    .cron <name> <period> <eventname> [<tz>] with param1=value1
    .cron <name> <period> <eventname> [<tz>] with param1=value1 param2=value2
    .cron <name> <period> <eventname> [<tz>] with param1=long value with spaces param2=value2
        will create or update a job with unique identifier <name>
        the <period> has to match a valid cronjob syntax of type * * * * *
        if 6 items are provided (ie. * * * * * *), the first one will be the seconds
        the optional <tz> will be applied if provided
        if no eventname is provided, the job will not emit anything

        This also can be used to modify an existing job.
        If the tz and data are omitted they will not be changed

        Data params can be provided if you add 'with' and a list
        of attributions. There is a drawback, which is that in the
        current implementation, the values can't contain an equal sign ('=')

        example:
        .cron blah */5 * * * * * cron.message
            will emit a cron.message every 5 seconds
            that event requires 2 data params, room and message:
            .cron blah room = shell
            .cron blah message = tick tack
        or
        .cron blah */5 * * * * * cron.message with room=shell message=tick tack
        .cron start blah
            activates the job, which will run every 5 seconds
        .cron blah * * * * * 
            modifies the job blah to run every minutes instead
            and it will emit the same event cron.message
            and it will keep the already set data
            note that modifying a job stops it, 
            so it has to be restarted afterward
        .cron start blah
            now the job is active and will run every minute

    .cron status <name>
        tells if the job is running or paused

    .cron info <name>
    .cron show <name>
        gives the details about a job

    .cron list [<term>]
        lists all the jobs, or only the jobs with names matching <term>

    .cron stop <name>
    .cron pause <name>
        stops the job <name>

    .cron start <name>
    .cron resume <name>
        starts the job <name>

    .cron delete <name>
        delete the job <name>

    .cron <name> <key> = <value>
        sets a key-value pair in the job data
        if the key already exists, its value will be changed
        if you change the data for job that is currently running
        it will be stopped and restarted 
    
    .cron <name> drop <key>
        removes a key-value pair form the job data
        this will also restart the job if it's running

Some events receivers are also provided for testing purposes:

    cron.message
        requires data:
        - room
        - message
        it will just say the message in the given room

    cron.date
        requires data:
        - room
        it will tell the date on the room

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
