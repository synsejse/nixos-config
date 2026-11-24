{
  # Keep pkexec available independently of desktop or package defaults.
  security.polkit = {
    enable = true;
    enablePkexecWrapper = true;
  };

  services.kmscon.enable = true;

  # Bound systemd journal storage alongside coredumps.
  services.journald.settings.Journal = {
    SystemMaxUse = "500M";
  };

  # Bound temporary crash-dump processing as well as retained dump files.
  systemd.coredump.settings.Coredump = {
    Storage = "external";
    Compress = true;
    ProcessSizeMax = "256M";
    ExternalSizeMax = "256M";
    MaxUse = "1G";
    KeepFree = "4G";
  };

  services.earlyoom = {
    enable = true;
    enableNotifications = true;
  };

  zramSwap = {
    enable = true;
    memoryPercent = 25;
    algorithm = "zstd";
    priority = 100;
  };
}
