{
  lib,
  pnpm_9,
  fetchFromGitHub,
  stdenv,
  makeWrapper,
  nodejs,
  python3,
  sqlite,
  srcOnly,
  nix-update-script,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "jellyseerr";
  version = "2.1.0";

  src = fetchFromGitHub {
    owner = "Fallenbagel";
    repo = "jellyseerr";
    rev = "v${finalAttrs.version}";
    hash = "sha256-5kaeqhjUy9Lgx4/uFcGRlAo+ROEOdTWc2m49rq8R8Hs=";
  };

  pnpmDeps = pnpm_9.fetchDeps {
    inherit (finalAttrs) pname version src;
    hash = "sha256-xu6DeaBArQmnqEnIgjc1DTZujQebSkjuai9tMHeQWCk=";
  };

  buildInputs = [
    sqlite
  ];

  nativeBuildInputs = [
    python3
    nodejs
    makeWrapper
    pnpm_9.configHook
  ];

  preBuild = ''
    export npm_config_nodedir=${srcOnly nodejs}
    pushd node_modules
    pnpm rebuild bcrypt sqlite3
    popd
  '';

  buildPhase = ''
    runHook preBuild

    pnpm build
    pnpm prune --prod --ignore-scripts
    # Clean up broken symlinks left behind by `pnpm prune`
    find node_modules/.bin -xtype l -delete

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share
    cp -r -t $out/share .next node_modules dist config package.json

    runHook postInstall
  '';

  postInstall = ''
    mkdir -p $out/bin
    makeWrapper '${nodejs}/bin/node' "$out/bin/jellyseerr" \
      --add-flags "$out/share/dist/index.js" \
      --set NODE_ENV production
  '';

  passthru.updateScript = nix-update-script { };

  meta = with lib; {
    description = "Fork of overseerr for jellyfin support";
    homepage = "https://github.com/Fallenbagel/jellyseerr";
    longDescription = ''
      Jellyseerr is a free and open source software application for managing
      requests for your media library. It is a a fork of Overseerr built to
      bring support for Jellyfin & Emby media servers!
    '';
    license = licenses.mit;
    maintainers = with maintainers; [ camillemndn ];
    platforms = platforms.linux;
    mainProgram = "jellyseerr";
  };
})
