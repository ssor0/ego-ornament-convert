# ego-ornament-convert

Based on the documentation of the different formats by petar tasev [here](https://github.com/EgoEngineModding/Ego-Engine-Modding/blob/master/src/010%20Templates/ornaments.bt)

Converts `ornaments.bin` file between the different formats used in older (ego 1.0 to 3.0) codemasters ego games, and is a part of
the process of using/converting tracks themselves between games.

This file is responsible for setting the transform (position, rotation and scale) and other properties of each ornament instance
used by a route of a track (in `objects.pssg` and `route_objects.pssg`). "ornaments" essentially "decorate" (and can vary by route) the track and are almost any 3d asset that appears on a track other than the
terrain surface, trees or crowd (which are handled by similar files, there is another in progress tool for converting trees.bin [here](https://github.com/EgoEngineModding/Ego-Engine-Modding/pull/105))

this tool is still a work in progress and will likely eventually be integrated into [ego file converter](https://github.com/EgoEngineModding/Ego-Engine-Modding#ego-file-converter).
only certain conversions have been tested and there are very likely bugs or compatibility problems with others files when converting to or from certain formats 
(some of which are known and others not, which will eventually be documented).


## Usage

precompiled versions for windows can be downloaded from [releases](https://github.com/ssor0/ego-ornament-convert/releases)

Example: `bin_convert -ik ds -ok d3 "steamapps/common/DiRT Showdown/tracks/locations/cities/miami/route_0/ornaments.bin"`
would convert `ornaments.bin` for miami route 0 from dirt showdowns format to dirt 3 and create the file `output_d3.bin`

The file `output_<format_kind>.bin` will be created in the directory the program was run, `<format_kind>` is the format set with `-ok`.
it can be renamed to `ornaments.bin` and placed in the route folder of a track.

Help message of program:
```
bin_convert [options] -ik <input format kind> -ok <output format kind> <file.bin>
[ ] = optional, < > = required, | = or

required:
  -ik <input kind> : format of input file

  -ok <output kind> : format of output file

  <file.bin> : path to track route bin file

formats kinds (d2 same as f1_others, ga same as dr):
  RDG       (Grid 2008)
  D2        (Dirt 2)
  F1_2010   (F1 2010)
  F1_OTHERS (F1 2011 - 2014)
  D3        (Dirt 3)
  DS        (Dirt Showdown)
  G2        (Grid 2)
  GA        (Grid Autosport)
  DR        (Dirt Rally 1)

options:
  -itag <same | inc | dec | inst_id> : behavior of setting instance tag when missing from input

  -iref_sort : sort inst by iref id

  -fo <ornament_name_string> : force all instances to use a specific ornament

  -verbose : print what is happening

  -b : print build date

  -h : show help message
```




## Compilation
  1. download gnat compiler: [windows](https://github.com/alire-project/GNAT-FSF-builds/releases/download/gnat-15.3.0-1/gnat-x86_64-elf-windows64-x86_64-15.3.0-1.tar.gz), [mac os](https://github.com/alire-project/GNAT-FSF-builds/releases/download/gnat-15.3.0-1/gnat-x86_64-darwin-15.3.0-1.tar.gz), look for packages containing `gnat` if using linux
  2. run `<path to bin folder of gnat>/gnatmake -gnata bin_test.adb`
  3. `bin_test(.exe)` should appear in the current directory




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


