# A system tray that shows nothing, so that VK WorkSpace sends its desktop
# notifications: it drops every one of them ("notification disable: system
# tray unavailable" in ~/.config/VK WorkSpace/logs/) unless
# QSystemTrayIcon::isSystemTrayAvailable(), and xmonad with xmobar has no tray.
# Qt deems the tray available as soon as org.kde.StatusNotifierWatcher (the
# StatusNotifierItem tray protocol) has an owner on the session bus, checked
# once on application start: restart VK WorkSpace after this service first
# comes up. The notifications themselves then go to dunst.
#
# The icons registered here go nowhere, and other apps believe in the tray
# too: those that hide to the tray when their window is closed come back only
# by launching them again.
{ pkgs, ... }:
let
  python = pkgs.python3.withPackages (pythonPackages: [ pythonPackages.dbus-fast ]);

  watcher = pkgs.writeScript "status-notifier-watcher-stub" ''
    #!${python}/bin/python3
    import asyncio
    import sys

    from dbus_fast import BusType, NameFlag, RequestNameReply
    from dbus_fast.aio import MessageBus
    from dbus_fast.service import PropertyAccess, ServiceInterface, dbus_property, method, signal

    BUS_NAME = "org.kde.StatusNotifierWatcher"


    class StatusNotifierWatcher(ServiceInterface):
        """Accepts every registration and keeps none: there is no host to show items."""

        def __init__(self):
            super().__init__(BUS_NAME)

        @method()
        def RegisterStatusNotifierItem(self, service: "s"):
            self.StatusNotifierItemRegistered(service)

        @method()
        def RegisterStatusNotifierHost(self, service: "s"):
            pass

        @dbus_property(access=PropertyAccess.READ)
        def RegisteredStatusNotifierItems(self) -> "as":
            return []

        # Read by libappindicator and Electron apps; Qt only checks the bus name
        @dbus_property(access=PropertyAccess.READ)
        def IsStatusNotifierHostRegistered(self) -> "b":
            return True

        @dbus_property(access=PropertyAccess.READ)
        def ProtocolVersion(self) -> "i":
            return 0

        @signal()
        def StatusNotifierItemRegistered(self, service) -> "s":
            return service

        @signal()
        def StatusNotifierItemUnregistered(self, service) -> "s":
            return service

        @signal()
        def StatusNotifierHostRegistered(self):
            pass

        @signal()
        def StatusNotifierHostUnregistered(self):
            pass


    async def main():
        bus = await MessageBus(bus_type=BusType.SESSION).connect()
        bus.export("/StatusNotifierWatcher", StatusNotifierWatcher())
        reply = await bus.request_name(BUS_NAME, NameFlag.DO_NOT_QUEUE)
        if reply != RequestNameReply.PRIMARY_OWNER:
            sys.exit(f"{BUS_NAME} is already owned (reply {reply.name}): another tray is running")
        await bus.wait_for_disconnect()


    asyncio.run(main())
  '';
in
{
  home-manager.users.hinidu.systemd.user.services.status-notifier-watcher-stub = {
    Unit = {
      Description = "System tray stub (StatusNotifierWatcher without a host)";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session-pre.target" ];
    };
    Service = {
      # Ready once it owns the bus name
      Type = "dbus";
      BusName = "org.kde.StatusNotifierWatcher";
      ExecStart = "${watcher}";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
