# ego-ornament-convert

based on the documentation of the different formats by petar tasev (here)[https://github.com/EgoEngineModding/Ego-Engine-Modding/blob/master/src/010%20Templates/ornaments.bt]

converts the `ornaments.bin` between the different formats used in older codemasters ego games, this
file is responsible for setting the transform (position and rotation) and other properties of each ornament instance
used by a route of a track. "ornaments" essentially "decorate" the track and are almost any 3d asset that appears on a track other than the
terrain surface, trees or crowd. (there is another in progress tool for converting trees.bin (here)[https://github.com/EgoEngineModding/Ego-Engine-Modding/pull/105])

this tool is still a work in progress and will likely eventually be integrated into (ego file converter)[https://github.com/EgoEngineModding/Ego-Engine-Modding#ego-file-converter],
only some conversions have been tested


usage: `bin_test <path to ornaments.bin file> -ik <format> -ok <format>`
  - `-ik` sets input format
  - `-ok` sets output format
  -  formats kinds:
    - `RDG` (race driver grid)
    - `D2` (dirt 2)
    - `F1_2010`
    - `F1_OTHERS` (f1 2011 - 2014, same as dirt 2)
    - `D3` (dirt 3)
    - `DS` (dirt showdown)
    - `G2` (grid 2)
    - `GA` (grid autosport)
    - `DR` (dirt rally 1, same as GA)



compilation:
  1. download gnat compiler: (windows)[https://github.com/alire-project/GNAT-FSF-builds/releases/download/gnat-15.3.0-1/gnat-x86_64-elf-windows64-x86_64-15.3.0-1.tar.gz], (mac os)[https://github.com/alire-project/GNAT-FSF-builds/releases/download/gnat-15.3.0-1/gnat-x86_64-darwin-15.3.0-1.tar.gz], look for packages containing `gnat` if using linux
  2. run `<path to bin folder of gnat>/gnatmake -gnata bin_test.adb`
  3. `bin_test(.exe)` should appear in the current directory
