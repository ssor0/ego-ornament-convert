# ego-ornament-convert

based on the documentation of the different formats by petar tasev [here](https://github.com/EgoEngineModding/Ego-Engine-Modding/blob/master/src/010%20Templates/ornaments.bt)

converts the `ornaments.bin` between the different formats used in older codemasters ego games, this
file is responsible for setting the transform (position and rotation) and other properties of each ornament instance
used by a route of a track. "ornaments" essentially "decorate" the track and are almost any 3d asset that appears on a track other than the
terrain surface, trees or crowd. (there is another in progress tool for converting trees.bin [here](https://github.com/EgoEngineModding/Ego-Engine-Modding/pull/105))

this tool is still a work in progress and will likely eventually be integrated into [ego file converter](https://github.com/EgoEngineModding/Ego-Engine-Modding#ego-file-converter)



compilation:
  1. download gnat compiler: [windows](https://github.com/alire-project/GNAT-FSF-builds/releases/download/gnat-15.3.0-1/gnat-x86_64-elf-windows64-x86_64-15.3.0-1.tar.gz), [mac os](https://github.com/alire-project/GNAT-FSF-builds/releases/download/gnat-15.3.0-1/gnat-x86_64-darwin-15.3.0-1.tar.gz), look for packages containing `gnat` if using linux
  2. run `<path to bin folder of gnat>/gnatmake -gnata bin_test.adb`
  3. `bin_test(.exe)` should appear in the current directory


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

the file `output_test` will be created in the directory the program was run,
it can be renamed to `ornaments.bin` and placed in the route folder of a track.






last 000000010170ed10


## notes

- objects.ens `TEMPLATEENTITYINSTANCE`
for objects/ornaments that have rigid body physics?
have own `instanceId` and `instanceTag` that share range with `ornaments.bin`
even though instance itself does not appear in file. `id` and `uri` attributes are same as basic entity (static ornament)
so next `instance` in `ornaments.bin` will use an `instanceId` value from where the
previous entity left off

- objects.ens `TEMPLATEBASICENTITYINSTANCE`
for static objects/ornaments that cant be moved?
has same `instanceTag` of corresponding instance in `ornaments.bin`, shares range with `ornaments.bin`.
does not have `instanceId` attribute but still shares range with values in `ornaments.bin`
so next `TEMPLATEENTITYINSTANCE` in `objects.ens` will use an `instanceId` value from where the
previous ornament instance left off

### objects.ens
binary pssg file in older games, xml pssg in newer games (also seems to be ordered, arranged in local hierarchy)?

### ornaments.bin, xml


