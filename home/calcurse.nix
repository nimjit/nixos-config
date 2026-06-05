{ ... }: {
  xdg.configFile."calcurse/conf".source = ./dotfiles/calcurse/conf;
  xdg.configFile."calcurse/keys".source = ./dotfiles/calcurse/keys;
  # caldav/config is NOT managed here — it contains OAuth secrets
}
