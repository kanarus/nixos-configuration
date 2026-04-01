{ pkgs, nur, ... }:
{
  programs.firefox = {
    enable = true;
    policies = {
      "BlockAboutAddons" = true;   # block about:addons   (GUI addons manager)
      "BlockAboutConfig" = true;   # block about:config   (GUI config manager)
      "BlockAboutProfiles" = true; # block about:profiles (GUI profiles manager)
      "FirefoxHome" = {
        "Search" = false;
        "TopSites" = false;
        "SponsoredTopSites" = false;
        "Highlights" = false;
        "Pocket" = false;
        "SponsoredPocket" = false;
        "Stories" = false;
        "SponsoredStories" = false;
        "Snippets" = false;
        "Locked" = false;
      };
      "Preferences" = {
        "browser.translations.automaticallyPopup" = false;
        "toolkit.scrollbox.verticalScrollDistance" = 5;
        "general.smoothscroll.lines.durationMaxMs" = 600;
        "general.smoothscroll.lines.durationMinMs" = 400;
        "general.smoothscroll.pages.durationMaxMs" = 500;
        "general.smoothscroll.currentVelocityWeighting" = 0;
      };
      "ExtensionSettings" = {
        "*" = {
          "installation_mode" = "blocked"; # block any other addons not listed below
        };
        "uBlock0@raymondhill.net" = {
          "installation_mode" = "force_installed";
          "install_url" = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
        };
      };
    };
  };
}
