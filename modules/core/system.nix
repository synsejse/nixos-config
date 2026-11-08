{
  # Keep pkexec available independently of desktop or package defaults.
  security.polkit = {
    enable = true;
    enablePkexecWrapper = true;
  };

  services.kmscon.enable = true;

  # Bound temporary crash-dump processing as well as retained dump files.
  systemd.coredump.settings.Coredump = {
    Storage = "external";
    Compress = true;
    ProcessSizeMax = "256M";
    ExternalSizeMax = "256M";
    MaxUse = "1G";
    KeepFree = "4G";
  };

  zramSwap = {
    enable = true;
    memoryPercent = 25;
    algorithm = "zstd";
    priority = 100;
  };
}
