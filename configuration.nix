# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];
    
  programs.firefox = {
    package = pkgs.latest.firefox-nightly-bin;
    enable = true;
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  
  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.plymouth.enable = true;
  boot.loader.timeout = 0;
  boot.loader.efi.canTouchEfiVariables = true;
  
  hardware.openrazer.enable = true;

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";
  nixpkgs.overlays =
  let
    # Change this to a rev sha to pin
    moz-rev = "master";
    moz-url = builtins.fetchTarball { url = "https://github.com/mozilla/nixpkgs-mozilla/archive/${moz-rev}.tar.gz";};
    nightlyOverlay = (import "${moz-url}/firefox-overlay.nix");
  in [
  nightlyOverlay
    # GNOME 46: triple-buffering-v4-46
    (final: prev: {
      gnome = prev.gnome.overrideScope (gnomeFinal: gnomePrev: {
        mutter = gnomePrev.mutter.overrideAttrs (old: {
          src = pkgs.fetchFromGitLab  {
            domain = "gitlab.gnome.org";
            owner = "vanvugt";
            repo = "mutter";
            rev = "triple-buffering-v4-46";
            hash = "sha256-C2VfW3ThPEZ37YkX7ejlyumLnWa9oij333d5c4yfZxc=";
          };
        });
      });
    })
  ];

  # gnome autologin
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;  

  # Set your time zone.
  time.timeZone = "Europe/Istanbul";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "tr_TR.UTF-8";
    LC_IDENTIFICATION = "tr_TR.UTF-8";
    LC_MEASUREMENT = "tr_TR.UTF-8";
    LC_MONETARY = "tr_TR.UTF-8";
    LC_NAME = "tr_TR.UTF-8";
    LC_NUMERIC = "tr_TR.UTF-8";
    LC_PAPER = "tr_TR.UTF-8";
    LC_TELEPHONE = "tr_TR.UTF-8";
    LC_TIME = "tr_TR.UTF-8";
  };
  
  # Switch to the lte (zen has temp isssues) kernel
  boot.kernelPackages = pkgs.linuxPackages_zen;

  programs.gamemode.enable = true;

  services.hardware.openrgb.enable = true;

  boot.kernelParams = [ # fix for need for speed unbound and heat
  "split_lock_detect=off"
  "video=HDMI-A-1:1920x1080@149"
  ];

  # Enable the Lenovo Legion Linux package
  boot.extraModulePackages = [ pkgs.linuxKernel.packages.linux_zen.lenovo-legion-module ];

  # Enable the X11 windowing system.
  # You can disable this if you're only using the Wayland session.
  services.xserver.enable = true;
  
  services.xserver.desktopManager.gnome.extraGSettingsOverridePackages = [pkgs.gnome.mutter];
  services.xserver.desktopManager.gnome.extraGSettingsOverrides = ''
        [org.gnome.mutter]
        experimental-features=['variable-refresh-rate', 'scale-monitor-framebuffer']
  '';

  # Enable the Gnome (kde behaves odd with external monitors with mux switch) Environment.
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  # Configure the Nvidia Drivers
  hardware.opengl = {
  enable = true;
  };
  services.xserver.videoDrivers = ["nvidia"];

  hardware.nvidia = {
  modesetting.enable = true; # required
  
  powerManagement = {
  enable = true;
  finegrained = false;
  };

  prime = {
    offload = {
      enable = false;
      enableOffloadCmd = false;
    };
    intelBusId = "PCI:0:2:0";
    nvidiaBusId = "PCI:1:0:0";
  };
  
  open = false;
  nvidiaSettings = true;
  package = config.boot.kernelPackages.nvidiaPackages.beta;
  };

  services.pipewire.wireplumber.enable = true;

  # Configure keymap in X11
  services.xserver = {
    layout = "tr";
    xkbVariant = "";
  };

  # Configure console keymap
  console.keyMap = "trq";

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.xperior = {
    isNormalUser = true;
    description = "xperior";
    extraGroups = [ "networkmanager" "wheel" "openrazer" "vboxusers" ];
    packages = with pkgs; [
      kdePackages.kate
    #  thunderbird
    ];
  };


  # Enable automatic login for the user.
  services.xserver.displayManager.autoLogin.enable = true;
  services.xserver.displayManager.autoLogin.user = "xperior";
  programs.dconf.enable = true;

  # Firefox constantly crashes on NVIDIA 555 Drivers

  hardware.bluetooth.enable = true; # enables support for Bluetooth
  # hardware.bluetooth.powerOnBoot = true; # powers up the default Bluetooth controller on boot

  # Enable Flatpaks
  services.flatpak.enable = true;
  fonts.fontDir.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
  
  services.earlyoom.enable = true; # prevent system from hanging when out of mem
  
  swapDevices = [{
    device = "/swapfile";
    size = 16 * 1024; # 16GB
  }];
  

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    ungoogled-chromium
    vesktop
    lenovo-legion
    openrazer-daemon
    pixelorama
    blender
    godot_4
    tor-browser
    monophony
    blockbench
    protonvpn-gui
    prismlauncher
    thunderbird
    freetype
    wineWowPackages.staging
    wineWowPackages.waylandFull
    morewaita-icon-theme
    gnomeExtensions.appindicator
    winetricks
    bottles
    xemu
    polychromatic
    rpcs3
    pcsx2
    moltengamepad
    dolphin-emu
    python312Packages.pip
    python312
    vscode-fhs
    cemu
    gparted
    vlc
    libgcc
    ffmpeg
    adwaita-icon-theme
    flex
    obs-studio
    spotify
    openrgb-with-all-plugins
    bison
    gcc_multi
    gcc
    ventoy
    gnome-tweaks
    kdePackages.ark
    kdePackages.konsole
    gnumake
    unrar
    steam-run
    python-launcher
    lm_sensors
    libratbag
    piper
    jdk22
    starship
    gtop
    pciutils
    wirelesstools
    iw
  ];

  programs.git = {
    enable = true;
  };

 # programs.firefox = { # hardware accel still crashes firefox on nvidia 555+ wayland
 # enable = true;
 # }; beta branch babyyyyyyyyyyy we onto sideways tabs
  
  services.cloudflare-warp = {
  enable = true;
  };
  
  environment.sessionVariables.MOZ_ENABLE_WAYLAND = "0";

  networking = {
    networkmanager.enable = true;
    nameservers = [ "127.0.0.1" "::1" ];
#     # If using dhcpcd:
     dhcpcd.extraConfig = "nohook resolv.conf";
#     # If using NetworkManager:
     networkmanager.dns = "none";
  };

  services.dnscrypt-proxy2 = {
    enable = true;
    settings = {
      ipv4_servers = true;
      ipv6_servers = true;
      require_nofilter = true;
      require_nolog = true;

      sources.public-resolvers = {
        urls = [
          "https://raw.githubusercontent.com/DNSCrypt/dnscrypt-resolvers/master/v3/public-resolvers.md"
          "https://download.dnscrypt.info/resolvers-list/v3/public-resolvers.md"
        ];
        cache_file = "/var/lib/dnscrypt-proxy2/public-resolvers.md";
        minisign_key = "RWQf6LRCGA9i53mlYecO4IzT51TGPpvWucNSCh1CBM0QTaLn73Y7GFO3";
      };

      # You can choose a specific set of servers from https://github.com/DNSCrypt/dnscrypt-resolvers/blob/master/v3/public-resolvers.md
      server_names = [ "cloudflare" ];
       
    };
  };

  systemd.services.dnscrypt-proxy2.serviceConfig = {
    StateDirectory = "dnscrypt-proxy";
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05"; # Did you read the comment?

}
