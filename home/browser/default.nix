{ pkgs, ... }:
{
  programs.firefox = {
    enable = true;
    policies = {
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
    };
  };
}
