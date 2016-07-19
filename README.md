# Remote shell using Net::Async::WebSocket

This work is based on https://github.com/vti/showmetheshell

## Changes

- Using `Net::Async::WebSocket` over `PocketIO`
- Using `IO::Tty::Util` over `IO::Pty`
  - `IO::Pty` create pipe only with already opened terminal.
  - You dont't have controll with which terminal you connect to.
  - If you open more then one connection, strange things happens (like ghost terminals)
  - `IO::Tty::Util::forkpty` **creates** new pseudoterminal for every new connection
- Cursor works :)
