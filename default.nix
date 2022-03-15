{
  python38
, zfs
, openssh
}:
python38.pkgs.buildPythonApplication {
  name = "zsnap";
  version = "0.1dev0";
  src = ./.;
  propagatedBuildInputs = with python38.pkgs; [
    click
    zfs
    openssh
  ];
}
