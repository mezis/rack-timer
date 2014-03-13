# rack-timer

Are you spending too much time in Rack middlewares?

Is one of your Rack middlewares misbehaving in production?

Add `RackTimer::Middleware` to the to of your middleware stack and figure out.

[![Build Status](https://travis-ci.org/mezis/rack-timer.png?branch=master)](https://travis-ci.org/mezis/rack-timer)

## Installation

Add this line to your application's Gemfile:

    gem 'rack-timer'

Add the middleware to your stack. In your `config.ru`, add this before any other
middleware:

    require 'rack-timer'
    use RackTimer::Middleware

When your app runs, it will output timing information to standard error.
If you want to change that, you can tell `rack-timer` to send data to another
file-y object, for instance:

    RackTimer.output = $stdout
    

## Usage

Run your app normally after installation, wait a while, and download your logs.

They will report the middleware starting up:

    [rack-timer] assimilating: Rack::MiddlewareTimer
    [rack-timer] assimilating: Rack::Lock
    [rack-timer] assimilating: Airbrake::UserInformer
    [rack-timer] assimilating: Rack::DetectCrawler

then timing each request:

    [borg] Proc took 3398135 us
    [rack-timer] Rack::Cors took 54 us
    [rack-timer] Rack::OutOfBandGC took 51 us
    ...
    [rack-timer] Airbrake::UserInformer took 74 us
    [rack-timer] Rack::Lock took 78 us
    [rack-timer] Rack::MiddlewareTimer took 80 us
    [rack-timer] queued for 5256 us

Besides middleware timing, two bits of extra information are reported:

- `Proc` (the first entry for each request) typically is your app itself
  (excluding middleware).
- `queued for...` will be present if your web frontend adds the `X-Request-Start`
  HTTP header. If using Nginx+Unicorn or Apache+Passenger, this will report the
  queueing time in Unicorn or Passenger.

## An example

We developed this because of wierd issues with queuing time (was too high
without an obvious reason).

We graphed the middleware timings:

![](http://cl.ly/image/460a3z060F3B/capture%202014-03-12%20at%2016.51.53.png)

And the queueing timings:

![](http://cl.ly/image/2D2336390628/capture%202014-03-12%20at%2013.25.43.png)

(horizontally: log10 of the queuing time in microseconds, ie. 3 is 1ms and 6 is
1 second)

The conlusion was that something what causing queuing in some cases. It turned
out our out-of-band garbage colleciton hack was no longer compatible with
Passenger, and removing it solved the issue:

![](http://cl.ly/image/3z0V40291P46/capture%202014-03-12%20at%2014.18.55.png)

## Contributing

1. Fork it ( http://github.com/<my-github-username>/rack-timer/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
