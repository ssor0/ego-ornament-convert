with system;
with system.memory;

with ada.text_io; use ada.text_io;
with ada.command_line;
with ada.directories;
with ada.streams.stream_io;

with ada.containers.vectors;
with ada.containers.indefinite_vectors;

with gnat.strings; use gnat.strings;

with interfaces; use interfaces;



procedure bin_test is

   package cli renames ada.command_line;

   package dir renames ada.directories;
   use type dir.file_kind;

   package sio renames ada.streams.stream_io;
   use type sio.count;


   subtype int32 is integer;
   type int32_array is array (int32 range <>) of int32;
   type int32_array_access is access int32_array;

   subtype int16 is integer_16;
   subtype ui8 is unsigned_8;
   subtype ui32 is unsigned_32;


   type cartesian_coord is (x, y, z, w);
   subtype coord_2d is cartesian_coord range x .. y;
   subtype coord_3d is cartesian_coord range x .. z;
   subtype coord_4d is cartesian_coord range x .. w;

   type transform_kind is (rotx, roty, rotz, pos);

   --type vec3 is array (coord_3d) of float;
   type point3 is array (coord_3d) of float;


   function "+" (right : in string) return string_access is
     (right'unrestricted_access);

   --  !   untyped free
   procedure free (pool_ptr : in system.address) is
      use type system.address;
      void_view : system.address with address => pool_ptr;
   begin
      if pool_ptr = system.null_address then
         put_line ("WARN   tried to free null address");
      else
         system.memory.free (pool_ptr);
         void_view := system.null_address;
      end if;
   end free;

   type gm is (rdg, d2, f1_2010, f1_others, d3, ds, g2, ga, dr);


   type bin_kind is (ornaments_bin, trees_bin, crowd_bin, unknown);



--    valid_types is array (bin_kind range ornaments_bin .. crowd_bin) of :=
--      ();
-- 

   --package ornament is
--    type ornament_instanceData (g : gm) is record
--       version : int32;
--       case g is
--       end case;
--    end record;
   --end ornament;

   --  ! use raw write and read to certain area of single large type?

   --  tree format
   --
   --  ver1 = d2, f1
   --  ver2 = d3, ds, g2
   --  ver3 = ga, dr


   --  ornament format
   --  gen, format, ver?
   --
   --  v1 = rdr?
   --  v2 = d2, f1 2011 - 2014
   --  v2.5 = f1 2010
   --  v3 = d3
   --  v4 = ds
   --  v5 = g2
   --  v6 = ga, dr

   --  if not generic
   --  ds to d2
   --  ds to d3
   --  ds to g2

   --  d2 to d3
   --  d2 to g2

   --  d3 to d2
   --  d3 to g2

   --  g2 to d2
   --  g2 to d3

   --  ga to g2


   --  ! file 'config' 'profile' array, i.e. numInstanceList or other 0
   --    doesnt add to file?

   --  d3 | ds | g2 | ga | dr
   --  !  not in dirt 2 or any f1 game
   type instanceData is record
      --  always same values
      instanceListOffset : int32 := 28;
      numInstanceList : int32 := 1;

      dependentListOffset : int32 := 80;
      numDependentList : int32 := 1;

      pathAnimRootOffset : int32 := 104;
      numPathAnimRoot : int32 := 1;
   end record;

   pragma compile_time_error (instanceData'size / 8 /= 24, "i d not correct size");


   type aabb_t is record
      boundsMin : point3;
      boundsMax : point3;
   end record;

   pragma compile_time_error (aabb_t'size / 8 /= 24, "b b not correct size");


   type instanceList is record  -- !  last
      --  all
      bounds : aabb_t;
--       boundsMin : point3;
--       boundsMax : point3;
      totalInstances : int32;  --  num of instance s between all instanceRef s
      instanceRefOffset : int32;  --  offset to first instanceRef?
      numInstanceRef : int32;  --  same as referenceNum (always same?)

      --  d3, ds, g2, ga, dr
      referenceNum : int32;  --  number of contained instanceRef s
      instanceOffset : int32;  --  offset to first instance of first ref?
      numInstance : int32;  --  can be but not always same as totalInstances?

      --  all but rdg
      totalLandmarks : int32 := 0;   --  instances of some type?
   end record;


   type instanceRef is record
      --  all
      fileNameOffset : ui32;

      -- ! d3 and later, no rdg d2 f1
      referenceId : int32;

      --  all
      bounds : aabb_t;
--       boundsMin : point3;
--       boundsMax : point3;

      --  all but rdg
      sponsor : int32 := 0;
      prebakedShadows : int32 := 0;

      --  all
      maxInstances : int32;
      renderTypeOffset : ui32;

      --  rdg, d2, all f1
      instancesOffset : int32;
      numInstances : int32 := 0;
      offset : int32;

      unknown : int32;  --  rdg has unknown value at end. pad?
   end record;

   type vec3 is array (coord_3d) of float;
   type matrix4_3 is array (transform_kind) of vec3;
   --  ! rotx roty rotz pos?
   pragma compile_time_error (matrix4_3'size / 8 /= 48, "m incorrect size");

   type rgba is array (positive range 1 .. 4) of unsigned_8 with pack;
   pragma compile_time_error (rgba'size / 8 /= 4, "r incorrect size");

   type instance_type is record  --  ! instance
      --  all
      transform : matrix4_3;
      color : rgba;

      --  d2, f1_2010, f1_others, d3, ds, g2, ga, dr
      godRayGroup : int32 := 0;
      dynamic : int32 := 0;

      --  all but rdg, f1_2010 (maybe rdg?)
      landmark : int32 := 0;  --  !  ?  (seen 0 in ga, d2, f1 2012 has various int)

      --  d3, ds, g2, ga, dr
      referenceId : int32;
      instanceId : int32;
      offsetSkyMap : ui32 := 0;
      doNotCastShadows : int32 := 0;
      instanceTag : int32;
      todSpecificOffset : ui32 := 16#FFFFFFFF#;  --  int32
      modeLayerOffset : ui32 := 16#FFFFFFFF#;  --  int32

      --  g2, ga, dr
      piaoTextureOffset : ui32 := 16#FFFFFFFF#;  --  ! int32, not seen if offset is max value if texture not present
      atlasU : int32 := 0;
      atlasV : int32 := 0;
      atlasW : int32 := 0;
      atlasH : int32 := 0;
      hueShiftIdOffset : ui32 := 16#FFFFFFFF#;  --  int32

      --  ga, dr
      sponsorHueShiftIdOffset : ui32 := 16#FFFFFFFF#;  --  int32

      --  f1 2010
      landmarkOffset : int16 := 0;   --  !   ?
      sessionVis : int16 := 0;  --   !   ?


      unknown : int32 := 0; --  ! rdg only, landmark? godRayGroup? dynamic?
   end record;

   --  d3, ds, g2, ga, dr only
   type dependentList is record
      referenceNum : int32 := 0;
      instanceNum : int32 := 0;
      dependentReferenceOffset : int32;  --  ! last byte of file before strings?
      numDependentReference : int32 := 0;
      dependentInstanceOffset : int32;  --  ! last byte of file before strings?
      numDependentInstance : int32 := 0;
   end record;

   pragma compile_time_error (dependentList'size / 8 /= 24, "d l not correct size");

   type dependentRef is record
      referenceId : int32 := 0;
      fileNameOffset : ui32;
      dependentTypeOffset : ui32;
      prebakedShadows : int32;
      bounds : aabb_t;
--       boundsMin : point3;
--       boundsMax : point3;
      maxInstances : int32;
   end record;

   pragma compile_time_error (dependentRef'size / 8 /= 44, "dr not correct size");

   type dependentInstance is record
      instanceId : int32;
      referenceId : int32;
      parentId : int32;
   end record;

   pragma compile_time_error (dependentInstance'size / 8 /= 12, "d i not correct size");


   type pathAnimRoot is record
      count : int32 := 0;
      pathAnimOffset : int32;   --  ! last byte of file before strings?
      numPathAnim : int32 := 0;
   end record;

   pragma compile_time_error (pathAnimRoot'size / 8 /= 12, "p a r not correct size");


   type pathAnim (g : gm) is record
      --  d3 and after
      id : int32;
      animClipNameOffset : ui32;
      instanceTag : int32;
      loops : int32;  --  ! loop
      cantTriggerEveryLap : int32;
      pingPong : int32;
      hideOnLoad : int32;
      hideWhenFinished : int32;
      heroAnim : int32;
      existProbability : int32;

      case g is
         when ds | g2 | ga | dr =>
            emitterOffset : int32;
            numEmitter : int32 := 0;
         when others =>
            null;
      end case;

   end record;

   --   !  + 4 is discriminant
   pragma compile_time_error ((pathAnim'size / 8) /= 48 + 4, "p a not correct size");

   --  ds after
   type emitter_type is record
      nameOffset : ui32;
      startTime : float;
      endTime : float;
      transform : matrix4_3;
   end record;


   pragma compile_time_error (emitter_type'size / 8 /= 60, "e not correct size");



   function as_float (v : in int32) return float is
      r : float with address => v'address;
   begin
      return r;
   end as_float;

   function as_int32 (v : in float) return int32 is
      r : int32 with address => v'address;
   begin
      return r;
   end as_int32;


-- 
--    function read_strings
--      (ifd     : sio.file_type;
--       istream : sio.stream_access) return string_list_access
--    is
--       temp : string (1 .. 255);
--       char_index : positive := 1;
-- 
--       str_count : natural := 0;
--       strings : string_list_access;
-- 
--       saved_index : constant sio.positive_count := sio.index (ifd);
-- 
--    begin
-- 
--       loop
--          character'read (istream, temp (1));
-- 
--          if temp (1) = character'val (0) then
--             str_count := str_count + 1;
--          end if;
-- 
--          exit when sio.end_of_file (ifd);
-- 
--       end loop;
-- 
--       --  ! check if str_count 0?
--       strings := new string_list (1 .. positive (str_count));
--       sio.set_index (ifd, saved_index);
-- 
-- 
--       for str_index in strings'range loop
--          character'read (istream, temp (char_index));
-- 
--          if temp (char_index) = character'val (0) then
-- 
--             --  !  includes null
--             strings (positive (str_count)) :=
--               new string'(temp (temp'first .. char_index));
-- 
--          end if;
-- 
--          char_index := char_index + 1;
-- 
--          exit when sio.end_of_file (ifd);
-- 
--       end loop;
-- 
--       return strings;
-- 
--    end read_strings;
-- 


--    function count_string_lengths
--      (ifd     : sio.file_type;
--       istream : sio.stream_access) return int32_array_access
--    is
--       char : character;
--       str_count : int32 := 1;
--       lengths : int32_array (0 .. 499) := (others => 0);
-- 
--    begin
--       put_line ("count string length");
-- 
--       loop
--          character'read (istream, char);
-- 
--          lengths (str_count) := lengths (str_count) + 1;
-- 
--          exit when sio.end_of_file (ifd);
-- 
--          if char = character'val (0) then
--             put_line ("str count" & str_count'image &  "  length" & lengths (str_count)'image);
--             str_count := str_count + 1;
--          end if;
-- 
--       end loop;
-- 
--       pragma assert (str_count <= lengths'last);
-- 
--       return new int32_array'(lengths (0 .. str_count - 1));
-- 
--    end count_string_lengths;
-- 





-- 
--    package string_vectors is new ada.containers.indefinite_vectors
--      (index_type => nint32,
--       element_type => string);



--    procedure read_string_area
--      (ifd     : sio.file_type;
--       istream : sio.stream_access;
--       sv : in out string_vectors.vector)
--    is
--       s : string (1 .. 255);
--       si : positive := s'first;
-- 
--    begin
--       put_line ("read string area");
-- 
--       loop
--          character'read (istream, s (si));
-- 
--          --lengths (str_count) := lengths (str_count) + 1;
-- 
--          if s (si) = character'val (0) then
--             --put_line ("str count" & str_count'image &  "  length" & lengths (str_count)'image);
--             sv.append (s (s'first .. si));
--             si := s'first;
--          end if;
-- 
--          exit when sio.end_of_file (ifd);
-- 
--          si := si + 1;
--          --str_count := str_count + 1;
-- 
--       end loop;
-- 
--       --pragma assert (str_count <= lengths'last);
-- 
--    end read_string_area;
-- 
-- 







   subtype nint32 is int32 range 0 .. int32'last;


   package instanceRef_vectors is new ada.containers.vectors
     (index_type => nint32,
     element_type => instanceRef);

   package instance_vectors is new ada.containers.vectors
     (index_type => nint32,
     element_type => instance_type);


   package dependentRef_vectors is new ada.containers.vectors
     (index_type => nint32,
     element_type => dependentRef);

   package dependentInstance_vectors is new ada.containers.vectors
     (index_type => nint32,
     element_type => dependentInstance);


   package pathAnim_vectors is new ada.containers.indefinite_vectors
     (index_type => nint32,
     element_type => pathAnim);

   package emitter_vectors is new ada.containers.vectors
     (index_type => nint32,
     element_type => emitter_type);






   type str_offset_kind is
     (sok_iref_fileName,
      sok_renderType,
      --  !  missing f1_2010 landmarkOffset?
      sok_SkyMap,
      sok_todSpecific,
      sok_modeLayer,
      sok_piaoTexture,
      sok_hueShiftId,
      sok_sponsorHueShiftId,
      sok_dref_fileName,
      sok_dependentType,
      sok_animClipName,
      sok_emitter_Name);

   type sok_state is array (str_offset_kind) of boolean;

   so_profiles : constant array (gm) of sok_state :=
     (rdg | d2 | f1_2010 | f1_others =>
        (sok_iref_fileName => true,
         sok_renderType => true,
         others => false),

      d3 =>
        (sok_iref_fileName => true,
         sok_renderType => true,
         sok_SkyMap => false,
         sok_todSpecific => true,
         sok_modeLayer => true,
         sok_piaoTexture => false,
         sok_hueShiftId => false,
         sok_sponsorHueShiftId => false,
         sok_dref_fileName => true,
         sok_dependentType => true,
         sok_animClipName => true,
         sok_emitter_Name => false),

      ds =>
        (sok_iref_fileName => true,
         sok_renderType => true,
         sok_SkyMap => false,
         sok_todSpecific => true,
         sok_modeLayer => true,
         sok_piaoTexture => false,
         sok_hueShiftId => false,
         sok_sponsorHueShiftId => false,
         sok_dref_fileName => true,
         sok_dependentType => true,
         sok_animClipName => true,
         sok_emitter_Name => true),

      g2 =>
        (sok_iref_fileName => true,
         sok_renderType => true,
         sok_SkyMap => true,
         sok_todSpecific => true,
         sok_modeLayer => true,
         sok_piaoTexture => true,
         sok_hueShiftId => true,
         sok_sponsorHueShiftId => false,
         sok_dref_fileName => true,
         sok_dependentType => true,
         sok_animClipName => true,
         sok_emitter_Name => true),

      ga | dr =>
        (others => true)  --  ! sponsorHueShiftId
     );

   type so_info_t is record
      offset_ol : sio.positive_count;
      value : ui32;
      kind : str_offset_kind;
   end record;

   package so_info_vectors is new ada.containers.vectors
     (index_type => nint32,
     element_type => so_info_t);

-- 
--    package ui32_vectors is new ada.containers.vectors
--      (index_type => nint32,
--      element_type => ui32);

--    function already_wr (so_info : in out so_info_vectors.vector; ci : nint32; value : ui32) is
--    begin
--       for info of so_info loop
--          if info.
--       end loop;
--    end already_wr;


--    type instanceRef_array is array (int32 range <>) of instanceRef;
--    type instanceRef_array_access is access instanceRef_array;
-- 
--    type instance_array is array (int32 range <>) of instance_type;
--    type instance_array_access is access instance_array;

   type o_b_type is record
      ik : gm;
      ifd : sio.file_type;  --  !  may be param
      istream : sio.stream_access;

      oK : gm;
      ofd : sio.file_type;
      ostream : sio.stream_access;

      version : int32;  --  always 0

      instance_data : instanceData;
      instance_list : instanceList;
      instance_refs  : instanceRef_vectors.vector;
      instances : instance_vectors.vector;


      act_total_instances : int32 := 0;  --  !  not original


      dependent_list : dependentList;
      dependent_refs : dependentRef_vectors.vector;
      dependent_instances : dependentInstance_vectors.vector;

      path_anim_root : pathAnimRoot;
      path_anims : pathAnim_vectors.vector;
      --emitter_info : pathAnim_emitter_info;  --  ! actually apart of pathANim

      total_emitters : int32 := 0;  --  ! not original

      emitters : emitter_vectors.vector;

      --strings : string_vectors.vector;

      --  !  string offsets of ifd, offset locations of ofd
      --string_offsets : ui32_vectors.vector;
      --offset_locations : ui32_vectors.vector;

      so_info : so_info_vectors.vector;

   end record;




   --  !  read file twice? only place needed to determine offsets?


   --  !  essentially 'header' size
   iref_offsets : constant array (gm) of int32 :=
     (rdg => 40,
      d2 | f1_2010 | f1_others => 44, -- (only seen f1 2012)
      d3 | ds | g2 | ga | dr => 116);


   iref_sizes : constant array (gm) of int32 :=
     (rdg => 52,
      d2 | f1_2010 | f1_others => 56,
      d3 | ds | g2 | ga | dr => 48);

      --  instance size
   instance_sizes : constant array (gm) of int32 :=
     (rdg => 56,
      d2 | f1_2010 | f1_others => 64,
      d3 | ds => 88,  --  !  correct?
      g2 => 116,
      ga | dr => 120);
   --  f1_2010 = 64 (int16 landmarkOffset, sessionVis instead of int32 


   pathAnim_size : constant array (gm) of int32 :=
     (d3 => 40,
      ds .. dr => 48,  --  ds, g2, ga, dr
      others => 0);

   emitter_size : constant array (gm) of int32 :=
     (d3 => 0,
      ds .. dr => 60, --  ds, g2, ga, dr
      others => 0);





   procedure read (ob : in out o_b_type) is

      subtype count_type is ada.containers.count_type;

      iK : gm renames ob.iK;
      ifd : sio.file_type renames ob.ifd;
      istream: sio.stream_access renames ob.istream;

      num_iref : int32 := -1;

      --instance_ref : instanceRef_vectors.reference_type;
      instance_ref : instanceRef;
      instance : instance_type;

      dref : dependentRef;
      dependent_instance : dependentInstance;

      emitter : emitter_type;

      --prev_inst_index
      previous_inst_id : int32 := 0;


      saved_index : sio.positive_count;

   begin
      put_line ("read");
      put_line ("version");

      int32'read (istream, ob.version);
      pragma assert (ob.version = 0);


      --  instanceData
      if ik in d3 .. dr then
         instanceData'read (istream, ob.instance_data);
         put_line ("instance data");
      end if;


      --  instanceList

      put_line ("instance list");

      aabb_t'read (istream, ob.instance_list.bounds);

      if ik in d3 .. dr then
         --int32'read (istream, instance_list.referenceNum);
         int32'read (istream, num_iref);
      end if;

      int32'read (istream, ob.instance_list.totalInstances);

      if ik in d2 .. dr then  --  ! all but rdg
         int32'read (istream, ob.instance_list.totalLandmarks);
      end if;

      int32'read (istream, ob.instance_list.instanceRefOffset);
      int32'read (istream, ob.instance_list.numInstanceRef);

      --  !  checks if numInstanceRef = referenceNum
      put_line ("num iref, rn" & num_iref'image);
      if num_iref /= -1 then
         pragma assert (ob.instance_list.numInstanceRef = num_iref);
      end if;
      num_iref := ob.instance_list.numInstanceRef;

      ob.instance_list.referenceNum := num_iref;


      --  

      --  offsets
      --  place file pos in array to return?
      --  add or subtract existing value?
      --
      --    instanceList.InstanceOffset
      --    instanceRef.instancesOffset
      --
      --    dependntList and pathAnimRoot offset can be set with add or s?
      --
      --    depdentList.fileNameOffset
      --    
      --
      --    strings
      --      instanceRef.fileNameOffset
      --      instance.offsetSkyMap? (only add if not FFFFFFFF)
      --      instance.todSpecificOffset? (only add if not FFFFFFFF) 
      --      instance.modeLayerOffset? (only add if not FFFFFFFF) 
      --      instance.piaoTextureOffset (only add if not FFFFFFFF) 
      --      instance.hueShiftIdOffset? (only add if not FFFFFFFF) 
      --      instance.sponsorHueShiftIdOffset? (only add if not FFFFFFFF) 
      --    hueShiftIdOffset (only add if not FFFFFFFF) 

      if ik in d3 .. dr then
         int32'read (istream, ob.instance_list.instanceOffset);
         int32'read (istream, ob.instance_list.numInstance);

         ob.act_total_instances := ob.instance_list.numInstance;

      end if;


      --  ! calculate certain fields for oK in read? 

      --  dependentList

      pragma assert (ob.instance_data.numDependentList >= 0);

      --if instance_data.numDependentList >= 1 then
      if ik in d3 .. dr then
         dependentList'read (istream, ob.dependent_list);
         put_line ("dependent list");
      end if;

      --  !  both default 0
      pragma assert (ob.dependent_list.referenceNum =
        ob.dependent_list.numDependentReference);

      pragma assert (ob.dependent_list.instanceNum =
        ob.dependent_list.numDependentInstance);

      --  pathAnimRoot

      if ik in d3 .. dr then
         pathAnimRoot'read (istream, ob.path_anim_root);
         put_line ("path anim root");
      end if;

      pragma assert (ob.path_anim_root.count = ob.path_anim_root.numPathAnim);

      --  !  have to know how many pathAnim have emitters for finding
      --     name string offset in advance
      --
      --    if input and output ds .. dr and numPathAnim > 0 have to jump
      --    to each pathAnim to read numEmitter from file for name offset
      --
      --  ! ds and after
--       if ik in ds .. dr and oK in ds .. dr and obpath_anim_root.count > 0 then
--          saved_index := sio.index (ifd);
--          sio.set_index (ifd, sio.positive_count (path_anim_root.pathAnimOffset + 1));
-- 
--          for pa_index in 0 .. path_anim_root.count - 1 loop
--             pathAnim'read (istream, path_anim);
--             pathAnim_emitter_info'read (istream, emitter_info);
--             --  ! no change if numEmitter 0
--             emitter_total := emitter_total + emitter_info.numEmitter;
--          end loop;
-- 
--          sio.set_index (ifd, saved_index);
--       end if;


      --  ! instanceref

      ob.instance_refs.reserve_capacity (count_type (num_iref));


      put_line ("instance ref");

      --  ! - 1 to make 0 based
      pragma assert (int32 (sio.index (ifd)) - 1 = iref_offsets (ik));


      if num_iref = 0 then
         put_line ("no instance ref");
         goto skip_instance_ref;
      end if;

      --ob.string_offsets.reserve_capacity (count_type (num_iref * 2));


      for iref_index in 0 .. num_iref - 1 loop

         ui32'read (istream, instance_ref.fileNameOffset);

         --  !  should never be FFFFFFFF
         pragma assert (instance_ref.fileNameOffset /= 16#FFFFFFFF#);
         pragma assert (instance_ref.fileNameOffset /= 0);
         --ob.string_offsets.append (instance_ref.fileNameOffset);


         if ik in d3 .. dr then
            int32'read (istream, instance_ref.referenceId);
            pragma assert (iref_index = instance_ref.referenceId);
         else
            --  ! separate var?
            instance_ref.referenceId := iref_index;
         end if;

         aabb_t'read (istream, instance_ref.bounds);

         case ik is
            when d3 .. dr =>
               int32'read (istream, instance_ref.sponsor);
               int32'read (istream, instance_ref.prebakedShadows);
               int32'read (istream, instance_ref.maxInstances);
               ui32'read (istream, instance_ref.renderTypeOffset);

               --   !  used in d3 michigan r0
               --pragma assert (instance_ref.renderTypeOffset = 16#FFFFFFFF#, "ir instance renderTypeOffset:  " & instance_ref.renderTypeOffset'image);

               --  !  (not present, maxInstances still not actual num)
               --instance_ref.numInstances := instance_ref.maxInstances;

            when d2 .. f1_others =>
               int32'read (istream, instance_ref.sponsor);
               int32'read (istream, instance_ref.prebakedShadows);
               int32'read (istream, instance_ref.maxInstances);
               int32'read (istream, instance_ref.offset);
               int32'read (istream, instance_ref.instancesOffset);
               int32'read (istream, instance_ref.numInstances);
               ui32'read (istream, instance_ref.renderTypeOffset);

               pragma assert (instance_ref.renderTypeOffset = 16#FFFFFFFF#);

               ob.act_total_instances :=
                 ob.act_total_instances + instance_ref.numInstances;

               put_line ("maxInstances " & instance_ref.maxInstances'image);
               put_line ("numInstances " & instance_ref.numInstances'image);

            when rdg =>
               int32'read (istream, instance_ref.maxInstances);
               int32'read (istream, instance_ref.offset);
               int32'read (istream, instance_ref.instancesOffset);
               int32'read (istream, instance_ref.numInstances);
               ui32'read (istream, instance_ref.renderTypeOffset);

               --  ! used in rdg det r0
               pragma assert (instance_ref.renderTypeOffset /= 0);

               int32'read (istream, instance_ref.prebakedShadows);  --  !  not confirmed
               --int32'read (istream, instance_ref.unknown);

               ob.act_total_instances :=
                 ob.act_total_instances + instance_ref.numInstances;

         end case;


         ob.instance_refs.append (instance_ref);

         --  !
         --  ! fails, not same
         --pragma assert (iK in rdg .. f1_others and instance_ref.maxInstances = instance_ref.numInstances);
--          iref_instance_nums (iref_index) := instance_ref.numInstances; --instance_ref.maxInstances;
--          inum_accum := inum_accum + instance_ref.maxInstances;
--          numInst_accum := numInst_accum + instance_ref.numInstances;

      end loop;


--       saved_index := sio.index (ofd);
--       sio.set_index (ofd, 77);  --  ! 76, + 1 to make 1 based
--       --  !  num inst in file
--       int32'write (ostream, numInst_accum);


--       for iref_index in fn_offsets'range loop
-- 
--          put_line ("f index " &  fn_offsets (iref_index)'image);
--          sio.set_index (ofd, fn_offsets (iref_index));
-- 
--          put_line ("s l" & name_lengths (iref_index)'image);
-- 
--          int32'write (ostream,
--            iref_offsets (oK) +
--            (num_iref * iref_sizes (oK)) +  --  size of all instanceRef
-- 
--             --  !! really broken? numInstance not present when iK certain value?
--            --(instance_list.numInstance * instance_sizes (oK)) +  --  size of all instances
--            (numInst_accum * instance_sizes (oK)) +  --  size of all instances
-- 
--            --  product 0 if no dependentList
--            (dependent_list.referenceNum * 44) +
--            (dependent_list.instanceNum * 12) +
--            --  product 0 if no pathAnimRoot
--            (path_anim_root.numPathAnim * pathAnim_size (oK)) +
--            (emitter_total * emitter_size (oK)) +
--            --  length of str before and null is offset to next,
--            --  length 0 for first (index 0) str
-- 
--             --  !! broken,  0 index already has 0
--            --(if iref_index = 0 then 0 else name_lengths (iref_index))
--            name_lengths (iref_index)
--          );
-- 
--       end loop;
-- 
--       sio.set_index (ofd, saved_index);
-- 

      --  instance

      put_line ("act total instances" & ob.act_total_instances'image);

      pragma assert (num_iref = int32 (ob.instance_refs.length));

--       for iref of ob.instance_refs loop
-- 
--          put_line ("iref id" & iref.referenceId'image);
--          if ik in d3 .. dr then
--             put_line ("inst count (not accurate)" & iref.maxInstances'image);
--          else
--             put_line ("inst count" & iref.numInstances'image);
--          end if;

         --  inst id
         --for inst_index in previous_inst_id .. previous_inst_id + iref_instance_nums (iref_index) - 1
         --  !  place start index in each ir?
         --for inst_index in 0 .. ob.act_total_instances - 1
           --previous_inst_id .. (iref.numInstances - 1) + previous_inst_id
         --loop

      put_line ("instance_refs.length" & ob.instance_refs.length'image);
      put_line ("instance_refs.last_index" & ob.instance_refs.last_index'image);

      if iK in d3 .. dr then
 
         --  d3, ds, g2, ga, dr
         for inst_index in 0 .. ob.act_total_instances - 1 loop

            int32'read (istream, instance.referenceId);
            int32'read (istream, instance.instanceId);

            put_line ("instance reference id" & instance.referenceId'image);
            put_line ("instance instance id" & instance.instanceId'image);

            --  ! correct?
            declare
               irr : instanceRef_vectors.reference_type :=
                 ob.instance_refs.reference (instance.referenceId);
            begin
               irr.numInstances := irr.numInstances + 1;
            end;

            --  !!   instances not in order
--                pragma assert (instance.referenceId = iref.referenceId,
--                  "instance rid" & instance.referenceId'image &
--                  "   iref rid" & iref.referenceId'image);

--             pragma assert (instance.instanceId = inst_index,
--               "instance i_id" & instance.instanceId'image &
--               "   inst index" & inst_index'image);

            matrix4_3'read (istream, instance.transform);

            if iK in g2 .. dr then
               ui32'read (istream, instance.offsetSkyMap);
               pragma assert (instance.offsetSkyMap = 0);
            end if;

            rgba'read (istream, instance.color);
            int32'read (istream, instance.godRayGroup);
            int32'read (istream, instance.dynamic);
            int32'read (istream, instance.doNotCastShadows);
            int32'read (istream, instance.landmark);

            int32'read (istream, instance.instanceTag);
            --instance.instanceTag := inst_index;

            ui32'read (istream, instance.todSpecificOffset);
            ui32'read (istream, instance.modeLayerOffset);

            --  !  string offset to specific game mode (seen in d3 bat)
            --put_line ("instance modeLayerOffset" & instance.modeLayerOffset'image);
            --pragma assert (instance.modeLayerOffset = 16#FFFFFFFF#);

            pragma assert (instance.offsetSkyMap = 0);

            --  g2, ga, dr
            if ik in g2 ..dr then
               ui32'read (istream, instance.piaoTextureOffset);
               int32'read (istream, instance.atlasU);
               int32'read (istream, instance.atlasV);
               int32'read (istream, instance.atlasW);
               int32'read (istream, instance.atlasH);
               ui32'read (istream, instance.hueShiftIdOffset);

               --put_line ("instance hueShiftIdOffset" & instance.hueShiftIdOffset'image);
               --pragma assert (instance.hueShiftIdOffset = 16#FFFFFFFF#);

               --if instance.piaoTextureOffset /= 16#FFFFFFFF# then
               --ob.string_offsets.append (instance.piaoTextureOffset);
               --end if;

               --  ga, dr
               if ik in ga | dr then
                  ui32'read (istream, instance.sponsorHueShiftIdOffset);
                  put_line ("instance sponsorHueShiftIdOffset" & instance.sponsorHueShiftIdOffset'image);
                  --pragma assert (instance.sponsorHueShiftIdOffset = 16#FFFFFFFF#);
               end if;

            end if;

            ob.instances.append (instance);

         end loop;  --  instance loop

      else
      --  rdg | d2 | f1_2010 | f1_others

         for instance_ref of ob.instance_refs loop

            put_line ("act num instance of ir"
              & instance_ref.numInstances'image);

            --  !  goto over loop if no instances? behavior same?

            for inst_index in previous_inst_id .. instance_ref.numInstances
              + previous_inst_id - 1
            loop

               --  !  instanceRef referenceId manually added to iK without it
               put_line ("reference id" & instance_ref.referenceId'image);
               put_line ("instance id" & inst_index'image);
               --put_line ("instances l " & ob.instances.length'image);

            --  !  instanceRef referenceId manually added to iK without it
               instance.referenceId := instance_ref.referenceId;
               instance.instanceId := inst_index;
               instance.instanceTag := inst_index;

               matrix4_3'read (istream, instance.transform);
               rgba'read (istream, instance.color);

               if iK /= rdg then
                  int32'read (istream, instance.godRayGroup);
                  int32'read (istream, instance.dynamic);

                  if iK = f1_2010 then
                     int16'read (istream, instance.landmarkOffset);
                     int16'read (istream, instance.sessionVis);
                  else  --  d2, f1_others
                     int32'read (istream, instance.landmark);
                  end if;

               else
                  --  rdg
                  int32'read (istream, instance.unknown);
               end if;

               ob.instances.append (instance);

            end loop;  --  instance loop

            --  !  val may be 0 or FFFFFFFF if not in ik
            --ob.string_offsets.append (instance.todSpecificOffset);
            --ob.string_offsets.append (instance.piaoTextureOffset);

            previous_inst_id := previous_inst_id + instance_ref.numInstances;

            new_line (1);

         end loop;  -- instanceRef loop

      end if;

         --  !  starts at 0, instanceNum, maxInstances of curr instanceRef
         --     start id of next
--          previous_inst_id := previous_inst_id + iref.numInstances;

--       end loop;  --  iref loop

      put_line ("act total instance" & ob.act_total_instances'image & "   instance.length" & ob.instances.length'image);
      pragma assert (ob.act_total_instances = int32 (ob.instances.length));


      --  !  make loop implicitly not enter if 0 iref
      <<skip_instance_ref>>


      --   dependentRef

      if ob.dependent_list.referenceNum > 0 then
         put_line ("dependent ref");
         ob.dependent_refs.reserve_capacity
           (count_type (ob.dependent_list.referenceNum));
      else
         put_line ("no dependent list");
      end if;

      for dref_index in 0 .. ob.dependent_list.referenceNum - 1 loop
         dependentRef'read (istream, dref);

         --  !  should never be FFFFFFFF
         pragma assert (dref.fileNameOffset /= 16#FFFFFFFF#);
         pragma assert (dref.fileNameOffset /= 0);
         pragma assert (dref.dependentTypeOffset /= 16#FFFFFFFF#);
         pragma assert (dref.dependentTypeOffset /= 0);
         --ob.string_offsets.append (dependent_ref.fileNameOffset);
         --ob.string_offsets.append (dependent_ref.dependentTypeOffset);

         pragma assert (dref.referenceId = dref_index);
         ob.dependent_refs.append (dref);
      end loop;


      --  dependentInstance

      if ob.dependent_list.instanceNum > 0 then
         put_line ("dependent instance");
         ob.dependent_refs.reserve_capacity
           (count_type (ob.dependent_list.instanceNum));
      else
         put_line ("no dependent instances");
      end if;

      for dinst_index in 0 .. ob.dependent_list.instanceNum - 1 loop
         dependentInstance'read (istream, dependent_instance);
         pragma assert (dependent_instance.instanceId = dinst_index);
         ob.dependent_instances.append (dependent_instance);
      end loop;

      --  pathAnim

      if ob.path_anim_root.numPathAnim > 0 then
         put_line ("path anim");
         ob.path_anims.reserve_capacity
           (count_type (ob.path_anim_root.numPathAnim));
      else
         put_line ("no path anim root");
      end if;

      for pa_index in 0 .. ob.path_anim_root.numPathAnim - 1 loop
         declare
            path_anim : pathAnim (ik);
         begin
            pathAnim'read (istream, path_anim);

            --  !  should never be FFFFFFFF
            pragma assert (path_anim.animClipNameOffset /= 16#FFFFFFFF#);
            pragma assert (path_anim.animClipNameOffset /= 0);
            --ob.string_offsets.append (path_anim.animClipNameOffset);

            pragma assert (path_anim.id = pa_index);
            --  ! emitterOffset, numEmitter only present after ds
            if iK in ds | g2 | ga | dr then
               ob.total_emitters := ob.total_emitters + path_anim.numEmitter;
            end if;
            ob.path_anims.append (path_anim);
         end;
      end loop;


      --   !   seek to contained data instead of doing in order?


      if ob.total_emitters > 0 then
         put_line ("emitter");
         ob.emitters.reserve_capacity (count_type (ob.total_emitters));
      else
         put_line ("no emitter");
      end if;

      for e_index in 0 .. ob.total_emitters - 1 loop
         emitter_type'read (istream, emitter);

         --  !  should never be FFFFFFFF
         pragma assert (emitter.nameOffset /= 16#FFFFFFFF#);
         pragma assert (emitter.nameOffset /= 0);
         --ob.string_offsets.append (emitter.nameOffset);

         ob.emitters.append (emitter);
      end loop;


      put_line ("ifd index" & sio.positive_count'image (sio.index (ifd) - 1));

      pragma assert (ui32 (sio.index (ifd)) - 1 =
        ob.instance_refs.first_element.fileNameOffset,
          "first fileNameOffset does not match ifd index");

      --   !  length of str area?

   end read;




   procedure write (ob : in out o_b_type) is

      use type ada.containers.count_type;

      oK : gm renames ob.oK;
      ofd : sio.file_type renames ob.ofd;
      ostream: sio.stream_access renames ob.ostream;

      --  actual num instances accumulate
      act_num_instances_accum : int32 := 0;
      --  ! offset accumulate
      offset_accum : int32 := 0;


   begin

      put_line ("write");

      put_line ("version");
      pragma assert (ob.version = 0);
      int32'write (ostream, ob.version);


      --  instanceData

      if ok in d3 .. dr then
         --  ! numDependentList and numPathAnimRoot default 1 if
         --    ik doesnt have them
         instanceData'write (ostream, ob.instance_data);
         put_line ("instance data");

      end if;

      --  instanceList

      put_line ("instance list");

      --  

      --  offsets
      --  place file pos in array to return?
      --  add or subtract existing value?
      --
      --    instanceList.InstanceOffset
      --    instanceRef.instancesOffset
      --
      --    dependntList and pathAnimRoot offset can be set with add or s?
      --
      --    depdentList.fileNameOffset
      --    
      --
      --    strings
      --      instanceRef.fileNameOffset
      --      instance.offsetSkyMap? (only add if not FFFFFFFF)
      --      instance.todSpecificOffset? (only add if not FFFFFFFF) 
      --      instance.modeLayerOffset? (only add if not FFFFFFFF) 
      --      instance.piaoTextureOffset (only add if not FFFFFFFF) 
      --      instance.hueShiftIdOffset? (only add if not FFFFFFFF) 
      --      instance.sponsorHueShiftIdOffset? (only add if not FFFFFFFF) 
      --    hueShiftIdOffset (only add if not FFFFFFFF) 


      aabb_t'write (ostream, ob.instance_list.bounds);

      if ok in d3 .. dr then
         --  referenceNum
         --put_line ("write referenceNum");
         --put_line ("ofd index" & sio.index (ofd)'image);

         put_line ("il rn" & ob.instance_list.referenceNum'image);
         put_line ("instance_refs.length" & ob.instance_refs.length'image);
         put_line ("instance_refs.last_index" & ob.instance_refs.last_index'image);

         --  !  referenceNum manually added to ik without it
         pragma assert (ob.instance_list.referenceNum =
           int32 (ob.instance_refs.length));
         int32'write (ostream, int32 (ob.instance_refs.length));
      end if;

      int32'write (ostream, ob.instance_list.totalInstances);

      if ok in d2 .. dr then
         --  default 0
         int32'write (ostream, ob.instance_list.totalLandmarks);
      end if;

      --  ! pre determine
      --  instanceRefOffset
      int32'write (ostream, iref_offsets (ok));

      --  numInstanceRef
      pragma assert (ob.instance_list.numInstanceRef =
        int32 (ob.instance_refs.length));
      --  ! always same as referenceNum?
      int32'write (ostream, int32 (ob.instance_refs.length));

      if ok in d3 .. dr then

         --  116 (instance ref offset) + (num instance ref * size of instance ref (48))
         --
         --  instanceRefOffset and size of instanceRef are same for all games
         --  that use instanceOffset
         --
         --  instance_list.instanceOffset
         int32'write (ostream, 116 + int32 (ob.instance_refs.length) * 48);

         --  numInstance
         --  act_total_instances num in file regardless of iK
         int32'write (ostream, ob.act_total_instances);

      end if;


      --  dependentList

      --  !  cant write for oK that use dependentList until know offset to file name area?

      --  ! offset also need to be updated for ik that have dependentList?

      if oK in d3 .. dr then
         put_line ("dependent list");

         --  !  dependentList only present with weather (rain, snow)?
         --  ! g2, ga never use dependentList?

         --  !!  have to determine for all but d3 <-> ds,
         --      ga <-> dr?

--          if ik in rdg .. f1_others or
--            (ik in d3 .. dr and dependent_list.referenceNum = 0)
--          then

        --  ! offset ignored if no dependentRef, can be anything?

        --  'num' fields default 0, replaced by above read if ik has dependentList
        ob.dependent_list.dependentReferenceOffset :=
          116 +  --  instanceData, instanceList, dependentList, pathAnimRoot
          int32 (ob.instance_refs.length) * 48 +  --  size of all instanceRef 48 in games that have dependentList
          ob.act_total_instances * instance_sizes (oK);  --  size of all instances
          --  ! above previously instance_list.numInstance

        --  ! numDependentReference?
        ob.dependent_list.dependentInstanceOffset :=
          ob.dependent_list.dependentReferenceOffset +
         (ob.dependent_list.referenceNum * 44);  --  same as above if no dependentRef

         dependentList'write (ostream, ob.dependent_list);

      end if;



      --  pathAnimRoot


      if oK in d3 .. dr then

         put_line ("path anim root");

         --  ! no change from dependentInstanceOffset if instanceNum 0
         ob.path_anim_root.pathAnimOffset := ob.dependent_list.dependentInstanceOffset
           + (ob.dependent_list.instanceNum * 12);

         pathAnimRoot'write (ostream, ob.path_anim_root);
      end if;

      pragma assert (ob.path_anim_root.count = ob.path_anim_root.numPathAnim);


      --   instanceref


      if ob.instance_refs.length = 0 then
         put_line ("no instance ref");
         goto skip_instance_ref;
      end if;

      put_line ("instance ref");

      pragma assert (int32 (sio.index (ofd)) - 1 = iref_offsets (oK));

      --ob.offset_locations.reserve_capacity (ob.string_offsets.length);

      for instance_ref of ob.instance_refs loop

         put_line ("writing instanceRef" & instance_ref.referenceId'image);

         --  fileNameOffset

         --ob.offset_locations.append (ui32 (sio.index (ofd)));
         ob.so_info.append
           ((offset_ol => sio.index (ofd),
             value => instance_ref.fileNameOffset,
             kind => sok_iref_fileName));

         --  !  previous manual calculation occurred here
         ui32'write (ostream, instance_ref.fileNameOffset);

         --  referenceId
         if oK in d3 .. dr then

            --   !  may not work?  see near l 850 (have to look in backup file)
            int32'write (ostream, instance_ref.referenceId);

         end if;

         --  boundsMin boundsMax
         aabb_t'write (ostream, instance_ref.bounds);

         case ok is

            when d3 .. dr =>
               int32'write (ostream, instance_ref.sponsor);  --  default 0
               int32'write (ostream, instance_ref.prebakedShadows); --  default 0

               --  !   seems to be same as old? (not neccessarily num of instances in file)
               int32'write (ostream, instance_ref.maxInstances);  --  all (not actual num in file)

               --   renderTypeOffset
               ob.so_info.append
                 ((offset_ol => sio.index (ofd),
                   value => instance_ref.renderTypeOffset,
                   kind => sok_renderType));

               ui32'write (ostream, instance_ref.renderTypeOffset); --  all


            when d2 .. f1_others =>
               int32'write (ostream, instance_ref.sponsor);  --  default 0
               int32'write (ostream, instance_ref.prebakedShadows); --  default 0
               int32'write (ostream, instance_ref.maxInstances);  --  all

               --  offset
               if ob.ik in d3 .. dr then
                  int32'write (ostream, offset_accum);
               else
                  --  ! doesnt have to be recalculated?
                  int32'write (ostream, instance_ref.offset);
               end if;

               --   instancesOffset
               int32'write (ostream,
                 iref_offsets (oK)
                   + (int32 (ob.instance_refs.length) * iref_sizes (oK))
                   + (act_num_instances_accum * instance_sizes (oK)) --  num_instance_of_all_preceeding_irefs * instances_sizes (oK)
               );

               --  offset_accum updated after instancesOffset write because current value needed for
               --  instancesOffset (offset to first instance of instanceRef)
               offset_accum := offset_accum + instance_ref.maxInstances;

               --  !  'offset' accum of maxInstances even if instances not
               --     in file, instancesOffset accum of num instances
               --     actually in file
               act_num_instances_accum := act_num_instances_accum + instance_ref.numInstances;

               --  numInstances (numInstances manually calculated during read for iK d3 .. dr)
               int32'write (ostream, instance_ref.numInstances);

               --   renderTypeOffset
               ob.so_info.append
                 ((offset_ol => sio.index (ofd),
                   value => instance_ref.renderTypeOffset,
                   kind => sok_renderType));

               ui32'write (ostream, instance_ref.renderTypeOffset);  --  all


            when rdg =>
               int32'write (ostream, instance_ref.maxInstances);  --  all

               --  offset
               if ob.ik in d3 .. dr then
                  int32'write (ostream, offset_accum);
               else
                  --  ! doesnt have to be recalculated?
                  int32'write (ostream, instance_ref.offset);
               end if;

               --   instancesOffset
               int32'write (ostream,
                 iref_offsets (oK)
                   + (int32 (ob.instance_refs.length) * iref_sizes (oK))
                   + (act_num_instances_accum * instance_sizes (oK)) --  num_instance_of_all_preceeding_irefs * instances_sizes (oK)
               );

               --  offset_accum updated after instancesOffset write because current value needed for
               --  instancesOffset (offset to first instance of instanceRef)
               offset_accum := offset_accum + instance_ref.maxInstances;

               --  !  'offset' accum of maxInstances even if instances not
               --     in file, instancesOffset accum of num instances
               --     actually in file
               act_num_instances_accum := act_num_instances_accum + instance_ref.numInstances;

               --  numInstances (numInstances manually calculated during read for iK d3 .. dr)
               int32'write (ostream, instance_ref.numInstances);


               --   renderTypeOffset
               ob.so_info.append
                 ((offset_ol => sio.index (ofd),
                   value => instance_ref.renderTypeOffset,
                   kind => sok_renderType));

               ui32'write (ostream, instance_ref.renderTypeOffset);  --  all

               int32'write (ostream, instance_ref.prebakedShadows);  --  ! not confirmed
               --int32'write (ostream, instance_ref.unknown);
         end case;

      end loop;


      --  instance

      put_line ("instance");

      put_line ("INSTANCES length" & ob.instances.length'image);


      for instance of ob.instances loop

         put_line ("inst id" & instance.instanceId'image);

         if oK in rdg | d2 | f1_2010 | f1_others then

            matrix4_3'write (ostream, instance.transform);  --  all
            rgba'write (ostream, instance.color);  --  !   all, conversion?

            if oK /= rdg then
               int32'write (ostream, instance.godRayGroup);
               int32'write (ostream, instance.dynamic);

               if oK = f1_2010 then
                  int16'write (ostream, instance.landmarkOffset);  --  ! default 0, can convert between lankmark and landmarkOffset, sessionVis?
                  int16'write (ostream, instance.sessionVis);  --  ! default 0
               else  --  d2, f1_others
                  int32'write (ostream, instance.landmark);  --  default 0
               end if;

            else
               --  rdg
               int32'write (ostream, instance.unknown);  --  ! default 0
            end if;

         else
         --  d3, ds, g2, ga, dr

            --  referenceId
            int32'write (ostream, instance.referenceId);
            --  instanceId
            int32'write (ostream, instance.instanceId);

            matrix4_3'write (ostream, instance.transform);  -- all

            if oK in g2 .. dr then
               ob.so_info.append ((sio.index (ofd), instance.offsetSkyMap, sok_SkyMap));
               ui32'write (ostream, instance.offsetSkyMap);
            end if;

            rgba'write (ostream, instance.color);  --  !  all, conversion?
            int32'write (ostream, instance.godRayGroup);  --  !  default 0
            int32'write (ostream, instance.dynamic);  --  !  default 0
            int32'write (ostream, instance.doNotCastShadows);  --  !  default 0
            int32'write (ostream, instance.landmark);  --  !  default 0, conversion? is offset?

            --  ! instangeTag
            --
            --  !  instanceTag is instanceId if iK rdg | d2 | f1_2010 | f1_others
            
            int32'write (ostream, instance.instanceTag);

            ob.so_info.append ((sio.index (ofd), instance.todSpecificOffset, sok_todSpecific));
            ui32'write (ostream, instance.todSpecificOffset);

            ob.so_info.append ((sio.index (ofd), instance.modeLayerOffset, sok_modeLayer));
            ui32'write (ostream, instance.modeLayerOffset);  --  ! need conversion? but never seen

            --  g2, ga, dr
            if ok in g2 ..dr then
               ob.so_info.append ((sio.index (ofd), instance.piaoTextureOffset, sok_piaoTexture));
               ui32'write (ostream, instance.piaoTextureOffset);  --  ! default FFFFFFFF
--                if ob.iK = g2 and oK in ga | dr then
--                   ui32'write (ostream, instance.piaoTextureOffset + 4);
--                elsif ob.ik in ga | dr and oK = g2 then
--                   ui32'write (ostream, instance.piaoTextureOffset - 4);
--                else
--                --  ! ik does not have piaoTextureOffset
--                   ui32'write (ostream, instance.piaoTextureOffset);  --  ! default FFFFFFFF
--                end if;

               --  !  only ever seen 0
               int32'write (ostream, instance.atlasU);
               int32'write (ostream, instance.atlasV);
               int32'write (ostream, instance.atlasW);
               int32'write (ostream, instance.atlasH);

               ob.so_info.append ((sio.index (ofd), instance.hueShiftIdOffset, sok_hueShiftId));
               ui32'write (ostream, instance.hueShiftIdOffset);
               --  ga, dr
               if ok in ga | dr then
                  ob.so_info.append ((sio.index (ofd), instance.sponsorHueShiftIdOffset, sok_sponsorHueShiftId));
                  ui32'write (ostream, instance.sponsorHueShiftIdOffset);
               end if;
            end if;

         end if;  --  oK condition

      end loop;  --  instance loop


      <<skip_instance_ref>>


      --   dependentRef

      put_line ("dependent ref");
      put_line ("dependent ref count (li) " & ob.dependent_refs.last_index'image);
      put_line ("dependent ref count (length)" & ob.dependent_refs.length'image);
      put_line ("iK " & ob.iK'image & "  oK " & oK'image);
      if oK in d3 .. dr and ob.dependent_refs.length > 0 then
         put_line ("writing dependent ref");

         for dref of ob.dependent_refs loop

            ob.so_info.append ((sio.index (ofd) + 4, dref.fileNameOffset, sok_dref_fileName));

            ob.so_info.append ((sio.index (ofd) + 8, dref.dependentTypeOffset, sok_dependentType));

            dependentRef'write (ostream, dref);
         end loop;

      end if;

      --  dependentInstance

      put_line ("dependent inst");
      put_line ("dependent inst count " & ob.dependent_instances.last_index'image);
      put_line ("iK " & ob.iK'image & "  oK " & oK'image);

      if oK in d3 .. dr and ob.dependent_instances.length > 0 then
         put_line ("writing dependent inst");
         for dependent_instance of ob.dependent_instances loop
            dependentInstance'write (ostream, dependent_instance);
         end loop;
      end if;


      --  pathAnim

      put_line ("path anim");
      put_line ("path anim count " & ob.dependent_refs.last_index'image);
      put_line ("iK " & ob.iK'image & "  oK " & oK'image);
      if oK in d3 .. dr and ob.path_anims.length > 0 then
         put_line ("writing path anim");
         for path_anim of ob.path_anims loop
            ob.so_info.append ((sio.index (ofd) + 4, path_anim.animClipNameOffset, sok_animClipName));
            pathAnim'write (ostream, path_anim);
         end loop;
      end if;

      --  emitter

      put_line ("emitter");
      put_line ("emitter count " & ob.emitters.last_index'image);
      put_line ("iK " & ob.iK'image & "  oK " & oK'image);
      if oK in d3 .. dr and ob.emitters.length > 0 then
         put_line ("writing emitter");
         for emitter of ob.emitters loop
            ob.so_info.append ((sio.index (ofd), emitter.nameOffset, sok_emitter_Name));
            emitter_type'write (ostream, emitter);
         end loop;
      end if;

      put_line ("ofd index" & sio.index (ofd)'image);

   end write;






   function read_nt_string (istream : sio.stream_access) return string is
      s : string (1 .. 255);
      si : positive := s'first;

   begin
      put_line ("read nt string");

      loop
         character'read (istream, s (si));

         if s (si) = character'val (0) then
            --put_line ("str count" & str_count'image &  "  length" & lengths (str_count)'image);
            return s (s'first .. si);
         end if;

         --exit when sio.end_of_file (ifd);

         si := si + 1;
         --str_count := str_count + 1;

      end loop;

      --  ! should never reach here
      pragma assert (false);

      return "";

   end read_nt_string;




   function read_nt_string (ifd : sio.file_type; pos : ui32) return string is

      istream : constant sio.stream_access := sio.stream (ifd);

      s : string (1 .. 255);
      si : positive := s'first;

      saved_index : constant sio.positive_count := sio.index (ifd);

   begin
      put_line ("read nt string at offset");

      sio.set_index (ifd, sio.positive_count (pos + 1));

      loop
         character'read (istream, s (si));

         if s (si) = character'val (0) then
            --put_line ("str count" & str_count'image &  "  length" & lengths (str_count)'image);
            sio.set_index (ifd, saved_index);
            return s (s'first .. si);
         end if;

         --exit when sio.end_of_file (ifd);

         si := si + 1;
         --str_count := str_count + 1;

      end loop;

      --  ! should never reach here
      pragma assert (false);

      sio.set_index (ifd, saved_index);

      return "";

   end read_nt_string;




   procedure update_string_offsets (ob : in out o_b_type) is

      ifd_first_string_offset : ui32 renames
        ob.instance_refs.first_element.fileNameOffset;

      pragma assert (ifd_first_string_offset = ui32 (sio.index (ob.ifd) - 1));

      ofd_sa_start : constant int32 := int32 (sio.index (ob.ofd)) - 1;

      --  ! positive difference if oK size larger, negative difference if
      --    oK size smaller
      sa_diff : constant int32 :=
        ofd_sa_start - int32 (sio.index (ob.ifd) - 1);


      sa_size : constant positive := positive (sio.size (ob.ifd) -
        sio.count (sio.index (ob.ifd) - 1));

      --  !  all_strings?
      i_string_area : string (1 .. sa_size);

   begin

      if ob.ik /= ob.oK or else
        (ob.ik not in d2 | f1_others and
         ob.oK not in d2 | f1_others)
      then
         pragma assert (sa_diff /= 0);
      end if;

      --  !  all string copied to output
      string'read (ob.istream, i_string_area);
      string'write (ob.ostream, i_string_area);

      put_line ("sa difference " & sa_diff'image);

      for info of ob.so_info loop

        if so_profiles (ob.oK) (info.kind) = true then

           put_line ("oK has " & info.kind'image);

            if info.value /= ui32'last and info.value /= 0 then
               sio.set_index (ob.ofd, info.offset_ol);
               int32'write (ob.ostream, int32 (info.value) + sa_diff);
            else
               put_line ("offset not used by ik");
            end if;

           --   ! offsets of later str not correct if one ib are removed?

           --  !  can write dummy data/still write str if going to game without?

           --  !  can leave out if from game without?

          --  ! elsif so_profiles (ob.iK) (info.kind) = true then
          --    !  offset is used, but not by oK. str written to keep later
          --       offsets aligned 

        end if;

      end loop;

      --  !   renderType after name of instanceRef name that uses it
      --  !  renderType? (shared)

      --   d3 later
      --    !  ir todSpecific (shared)

      --   g2 later
      --    !  modeLayer? (never seen)
      --    !  piaoTexture? (specific?)
      --    !  hueShiftId (shared)
      --   ga later
      --     sponsorHueShiftId (not seen)

      --   d3 later
      --      !  dependentRef filename
      --      !  dependentType name
      --      !  animCLipName
      --      !  emitter.nameOffset


   end update_string_offsets;





   function find (sub : in string; str : in string) return boolean is
      start : positive := 1;
   begin

      for start in str'range loop

         if sub'last > str'last - start then
            return false;
         elsif sub = str (start .. (start - 1) + sub'last) then
            return true;
         end if;

      end loop;

      return false;

   end find;


   function identify_file
     (ifd : in sio.file_type;
      stream : in sio.stream_access) return bin_kind
   is

      ornament_strings : constant string_list :=
        (+"core_", +"_brake", +"brake_", +"armco", +"sponsor", +"building");

      tree_strings : constant string_list :=
        (+"_tree", +"tree_", +"_palm", +"palm_", +"_bush", +"bush_");

      crowd_strings : constant string_list :=
        (+"xf_cr", +"f_cr", +"m_cr", +"_fin_", +"cameraman_", +"photographer_",
         +"_marshal_");

      patterns : constant array (bin_kind range ornaments_bin .. crowd_bin) of
        string_list_access :=
          (ornament_strings'unrestricted_access,
           tree_strings'unrestricted_access,
           crowd_strings'unrestricted_access);


      ifile_size : constant sio.count := sio.size (ifd);

      search_area : string (1 .. 50);

   begin
      sio.set_index (ifd, sio.positive_count (ifile_size - 50));
      string'read (stream, search_area);

      for kind_index in patterns'range loop
         for pattern of patterns (kind_index).all loop

            for tries in sio.count'(1) .. 100 loop
               if find (pattern.all, search_area) then
                  sio.set_index (ifd, 1);  --  start of file
                  return kind_index;
               end if;

               sio.set_index (ifd, sio.positive_count (ifile_size - 50 * tries));
               string'read (stream, search_area);
             end loop;

         end loop;
      end loop;

      return bin_kind'(unknown);

   end identify_file;




   type cli_argument_type is record
      required : boolean;
      switch : string_access;
      has_value : boolean;
      placeholder_val : string_access;
      description : string_access;
   end record;

   type argument_array is array (positive range <>) of cli_argument_type;

   --  arguments
   --
   --    name tree

   av_a : argument_array :=
     ((required => true,
       switch   => +"",
       has_value => true,
       placeholder_val => +"<file.bin>",
       description => +"path to track route bin file"),

      (required => true,
       switch   => +"-ik",  --  ! from?
       has_value => true,
       placeholder_val => +"<input kind>", --+"<input type>",
       description => +"format of input file"),

      (required => true,
       switch   => +"-ok",  --  ! to?
       has_value => true,
       placeholder_val => +"<output kind>",
       description => +"format of output file"),

      (required => false,
       switch   => +"-k",
       has_value => true,
       placeholder_val => +"",
       description => +"list format kinds"),

      (required => false,
       switch   => +"-h",
       has_value => false,
       placeholder_val => +"",
       description => +"show help message")
       );


   --type int32_array is array (positive range <>) of int32;

   procedure s_h is
   begin
      put_line ("usage: " & cli.command_name
        & " [-help] | <file> -ik <input format kind> -oK <output format kind>");
      put_line ("[ ] = optional, < > = required, | = or");
      put_line ("formats kinds");
      put_line ("  (d2 and f1_others are same)");
      put_line ("  (ga and dr are same)");
      for g in gm'range loop
         put_line ("    " & g'image);
      end loop;
   end s_h;



   kind : bin_kind;

   iformat : gm;
   oformat : gm;

   version_num : int32;
   second_4_bytes : float;

   ob : o_b_type;
   k_count : natural := 0;


begin

--    put_line (as_float (val_i)'image);
--    return;

--    put_line (integer'image (u'size / 8));
--    if cli.argument_count /= 3 then
--       put_line ("usage: " & cli.command_name & " ");
--       return;
--    elsif not dir.exists (cli.argument (1)) or else
--              dir.kind   (cli.argument (1)) /= dir.ordinary_file
--    then
--       put_line ("""" & cli.argument (1) & """ not valid file");
--       return;
--    elsif cli.argument (2) /= "-t" then
--       put_line ("unknown option """ & cli.argument (2) & """");
--       return;
--    elsif cli.argument (3) /-
--    end if;

   --put_line (integer'image (pathAnim'size / 8));
   --return;

--    for a_index in 1 .. cli.arguments loop
--       if av_a (a_index).required then
-- 
--       exit when a_index > av_a'last;
--    end loop;

   if cli.argument_count = 0 or else cli.argument (1) = "-help" then
      s_h;
      return;

   elsif cli.argument_count < 5 then
      put_line ("not enough arguments");
      s_h;
      return;

   elsif not dir.exists (cli.argument (1)) or else
      dir.kind (cli.argument (1)) /= dir.ordinary_file
   then
      put_line ("file """ & cli.argument (1) & """ not file");
      return;
   end if;


   for a_index in 2 .. cli.argument_count loop
      begin
         if cli.argument (a_index) = "-ik" then
            ob.iK := gm'value (cli.argument (a_index + 1));
            k_count := k_count + 1;
         elsif cli.argument (a_index) = "-ok" then
            ob.oK := gm'value (cli.argument (a_index + 1));
            k_count := k_count + 1;
         end if;

      exception
         when constraint_error =>
            put_line ("""" & cli.argument (a_index + 1) & """ invalid format");
            s_h;
            return;
      end;
   end loop;

   if k_count /= 2 then
      put_line ("specify formats with ""-ik"" and ""-oK""");
      return;
   end if;


   if ob.ik = ob.oK or
     (ob.ik in d2 | f1_others and
      ob.oK in d2 | f1_others)
   then
      put_line ("formats are same");
   end if;


   sio.open (ob.ifd, sio.in_file, cli.argument (1));
--    sio.open (ifile, sio.in_file, cli.argument (1));
--    sio.create (ofile, sio.out_file, "output_test");
   sio.create (ob.ofd, sio.out_file, "output_test");

--    iformat := d2;
--    oformat := d3;
-- 
--    o_b.ik := iformat;
   ob.istream := sio.stream (ob.ifd);
--    o_b.oK := oformat;
   ob.ostream := sio.stream (ob.ofd);


   kind := identify_file (ob.ifd, ob.istream);

   case kind is
      when ornaments_bin =>
         put_line ("o");
         read (ob);
         write (ob);
         update_string_offsets (ob);

      when trees_bin =>
         put_line ("t");
      when crowd_bin =>
         put_line ("c");
      when unknown =>
         put_line ("unknown");
   end case;


--    int32'read (istream, version_num);
--    float'read (istream, peek_read);
--    put_line (peek_read'image);
-- 
--    if peek_read < 0.00000 then
--       put_line ("d2 f1");
--    else
--       put_line ("other");
--    end if;

--    u.field_3 := 50;
--    u_test'read (istream, u);
-- 
--    put_line (u.field_1'image);
-- 
--    put_line (u.field_3'image);

   sio.close (ob.ifd);
   sio.close (ob.ofd);
end bin_test;
