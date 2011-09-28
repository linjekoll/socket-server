# Socket Server

Websocket Server used @ [linjekoll.se](http://linjekoll.se).

## Installation

Start by cloning the project using git.

`git clone git@github.com:linjekoll/socket-server.git`

Navigate to the downloaded folder and run bundler.

`cd socket-server && bundle install`

## Start the server

`bundle exec ruby ./server.rb`

Or start both beanstalkd and the server using [Foreman](http://railscasts.com/episodes/281-foreman).

`foreman start`

Default port is `3333`.

## Requirements

*WS* is tested in *OS X 10.7.1* using Ruby *1.9.2*.

## License

*WS* is released under the *MIT license*.