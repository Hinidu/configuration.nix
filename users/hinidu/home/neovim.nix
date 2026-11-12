{ config, osConfig, pkgs, ... }:

# A light nvim for commit messages and small edits; real coding happens in Zed.
{
  programs.neovim = {
    enable = true;
    plugins = with pkgs.vimPlugins; [
      NeoSolarized
      vifm-vim
      vim-airline
      vim-airline-themes
      vim-elixir
      vim-eunuch
      vim-fugitive
      vim-gitgutter
      vim-move
    ];
    # Before init.vim, which sets the color scheme
    extraConfig = ''
      set background=${osConfig.solarized.variant}
      let g:airline_solarized_bg = '${osConfig.solarized.variant}'
    '' + builtins.readFile ./neovim/init.vim;
  };
}
