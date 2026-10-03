pragma allow_integer_address;

with system;
with system.memory;
with system.address_image;

with ada.text_io;
--with ada.float_text_io; use ada.float_text_io;
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


   verbose : boolean := false;

   procedure put_line (s : in string) is
   begin
      case verbose is
         when false => null;
         when true => ada.text_io.put_line (s);
      end case;
   end put_line;

   procedure new_line (number : ada.text_io.positive_count) is
   begin
      case verbose is
         when false => null;
         when true => ada.text_io.new_line (number);
      end case;
   end new_line;


   procedure dprintf
     (fd     : in integer;
      format : in string;
      rot_xx, rot_xy, rot_xz, rot_xw,
      rot_yx, rot_yy, rot_yz, rot_yw,
      rot_zx, rot_zy, rot_zz, rot_zw,
      pos_x,  pos_y,  pos_z,  pos_w : in float)
   with import, convention => c_variadic_2;

   gnat_argv : System.Address;
   pragma Import (C, gnat_argv, "gnat_argv");

   function Len_Arg (Arg_Num : Integer) return Integer;
   pragma Import (C, Len_Arg, "__gnat_len_arg");

   subtype int32 is integer;
   type int32_array is array (int32 range <>) of int32;
   type int32_array_access is access int32_array;

--    function "+" (right : int32) return int32 is
--      (right + 1) with inline;
-- 
--    function "-" (right : int32) return int32 is
--      (right - 1) with inline;

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

      no_alloc : constant system.address := 16#FFFFFFFFFFFFFFF8#;

      void_view : system.address with address => pool_ptr;
   begin
      --put_line ("addr " & system.address_image (pool_ptr));
      --  !  doesnt work
--       if pool_ptr = system.null_address then
      if pool_ptr = no_alloc then
         put_line ("WARN   tried to free unallocated address");
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

   --   !  48 + 4 (4 is discriminant)
   --pragma compile_time_error ((pathAnim'size / 8) /= 48 + 4, "p a not correct size");
   unused_path_anim_size_test : pathAnim (dr);
   pragma compile_time_error (unused_path_anim_size_test'size / 8 /= 48 + 4, "p a not correct size");

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




   subtype nint32 is int32 range 0 .. int32'last;


   package instanceRef_vectors is new ada.containers.vectors
     (index_type => nint32,
     element_type => instanceRef);


   package instance_vectors is new ada.containers.vectors
     (index_type => nint32,
     element_type => instance_type);

   function "<" (left, right : instance_type) return boolean
     is (left.referenceId < right.referenceId);

   package iv_sorting is new instance_vectors.generic_sorting;


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



--    type instanceRef_array is array (int32 range <>) of instanceRef;
--    type instanceRef_array_access is access instanceRef_array;
-- 
--    type instance_array is array (int32 range <>) of instance_type;
--    type instance_array_access is access instance_array;

   type itag_option is (same, inc, dec, inst_id);

   --  ! args
   arg_count : constant natural := cli.argument_count;

   ik : gm;
   oK : gm;

   sort_by_iref : boolean := false;  -- ! older games already sorted
   itag_behav : itag_option := inst_id;
   force_ornament : boolean := false;
   fo_str : string (1 .. 255);
   fo_str_l : positive;
   ----

   type o_b_type is record
      ifd : sio.file_type;  --  !  may be param
      istream : sio.stream_access;

      ofd : sio.file_type;
      ostream : sio.stream_access;

      ens_ifd : ada.text_io.file_type;
      ens_ofd : ada.text_io.file_type;

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

      --  !  string offset values of ifd, offset locations of ofd
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

--  unused
--    emitter_size : constant array (gm) of int32 :=
--      (d3 => 0,
--       ds .. dr => 60, --  ds, g2, ga, dr
--       others => 0);





   procedure read (ob : in out o_b_type) is

      subtype count_type is ada.containers.count_type;

      --iK : gm renames ob.iK;
      ifd : sio.file_type renames ob.ifd;
      istream: sio.stream_access renames ob.istream;

      num_iref : int32 := -1;

      instance_ref : instanceRef;
      instance : instance_type;

      dref : dependentRef;
      dependent_instance : dependentInstance;

      emitter : emitter_type;

      --previous_inst_id : int32 := 0;

      itag_val : int32;

      instance_index : int32 := 0;

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


      --   instanceref

      put_line ("instance ref");

      ob.instance_refs.reserve_capacity (count_type (num_iref));

      --  ! - 1 to make 0 based
      pragma assert (int32 (sio.index (ifd)) - 1 = iref_offsets (ik));


      if num_iref = 0 then
         put_line ("no instance ref");
      end if;

      --  !  loop isnt run if num_iref = 0

      for iref_index in 0 .. num_iref - 1 loop

         ui32'read (istream, instance_ref.fileNameOffset);

         --  !  should never be FFFFFFFF
         pragma assert (instance_ref.fileNameOffset /= 16#FFFFFFFF#);
         pragma assert (instance_ref.fileNameOffset /= 0);


         if ik in d3 .. dr then
            int32'read (istream, instance_ref.referenceId);
            pragma assert (iref_index = instance_ref.referenceId);
            -- !  also tests order, should always be in order unlike inst
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
               pragma assert (instance_ref.renderTypeOffset /= 0);

            when d2 .. f1_others =>
               int32'read (istream, instance_ref.sponsor);
               int32'read (istream, instance_ref.prebakedShadows);
               int32'read (istream, instance_ref.maxInstances);
               int32'read (istream, instance_ref.offset);
               int32'read (istream, instance_ref.instancesOffset);
               int32'read (istream, instance_ref.numInstances);
               ui32'read (istream, instance_ref.renderTypeOffset);

               --  ! not seen yet
               pragma assert (instance_ref.renderTypeOffset /= 0);

               --  ! use instanceList.numInstance?
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

               int32'read (istream, instance_ref.prebakedShadows);  --  !  not confirmed, but always 0 or 1
               --int32'read (istream, instance_ref.unknown)

               ob.act_total_instances :=
                 ob.act_total_instances + instance_ref.numInstances;

         end case;

         pragma assert (instance_ref.maxInstances > 0);
         pragma assert (instance_ref.numInstances >= 0);  --  ! default 0

         ob.instance_refs.append (instance_ref);

      end loop;


      --  instance

      put_line ("act total instances" & ob.act_total_instances'image);

      --  !! will fail if empty instance list?
      pragma assert (ob.act_total_instances > 0);

      itag_val := (case itag_behav is
        when inc => 0,
        when dec => ob.act_total_instances,
        when others => 0);

      pragma assert (num_iref = int32 (ob.instance_refs.length));


      put_line ("instance_refs.length" & ob.instance_refs.length'image);
      put_line ("instance_refs.last_index" & ob.instance_refs.last_index'image);


      if iK in d3 .. dr then

         --  loop not run if 0 ir and inst

         --  d3, ds, g2, ga, dr
         for inst_index in 0 .. ob.act_total_instances - 1 loop

            int32'read (istream, instance.referenceId);
            int32'read (istream, instance.instanceId);

            put_line ("instance reference id" & instance.referenceId'image);
            put_line ("instance instance id" & instance.instanceId'image);


            --  !  rewrite instances in order of instance refs to see if will still work?

            --   !  tests if instances are in same order as irefs
            if inst_index > 0 then
               --  !  inst are in order by inst id but not ref id
               pragma assert (instance.instanceId > ob.instances.last_element.instanceId);
               --pragma assert (instance.referenceId >= ob.instances.last_element.referenceId);
            end if;


            declare
               irr : instanceRef_vectors.reference_type :=
                 ob.instance_refs.reference (instance.referenceId);
            begin

               pragma assert (irr.referenceId = instance.referenceId);

               irr.numInstances := irr.numInstances + 1;
            end;

            --  ! should be in order, but some iref only have instances in object.ens
            --  old:
            --  !!   instances not in order
--                pragma assert (instance.referenceId = iref.referenceId,
--                  "instance rid" & instance.referenceId'image &
--                  "   iref rid" & iref.referenceId'image);

            --  !  instanceid can start at any number depending on if first irefs
            --     are for ornaments with physics in objects.ens
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
            pragma assert (instance.todSpecificOffset /= 0);

            --  !  string offset to specific game mode (seen in d3 bat)
            ui32'read (istream, instance.modeLayerOffset);
            pragma assert (instance.modeLayerOffset /= 0);


            --  g2, ga, dr
            if ik in g2 ..dr then
               ui32'read (istream, instance.piaoTextureOffset);
               int32'read (istream, instance.atlasU);
               int32'read (istream, instance.atlasV);
               int32'read (istream, instance.atlasW);
               int32'read (istream, instance.atlasH);
               ui32'read (istream, instance.hueShiftIdOffset);

               pragma assert (instance.hueShiftIdOffset /= 0);
               pragma assert (instance.piaoTextureOffset /= 0);

               --  ga, dr
               if ik in ga | dr then
                  ui32'read (istream, instance.sponsorHueShiftIdOffset);
                  pragma assert (instance.sponsorHueShiftIdOffset /= 0);
               end if;

            end if;

            ob.instances.append (instance);

         end loop;  --  instance loop

      else
      --  rdg | d2 | f1_2010 | f1_others

         --  loop is not run if 0 ir

         for instance_ref of ob.instance_refs loop

            --   !  offset_accum + numInstances li?

            put_line ("ir offset " & instance_ref.offset'image);
            put_line ("act num instance of ir"
              & instance_ref.numInstances'image);


            if instance_ref.numInstances > 0 then
               --   !  instances are in same order of irefs in older games,
               --      makes sure pos in input fd is same as iref offset to instances.
               pragma assert (instance_ref.instancesOffset = int32 (sio.index (ob.ifd)) - 1);
            end if;

            --  loop is not run if instance_ref.numInstances is 0

            for inst_index in instance_ref.offset .. instance_ref.offset +
              instance_ref.numInstances - 1
            loop

            --  !  previous 0 indexed loop range
            --inst_index in previous_inst_id .. instance_ref.numInstances
            --  + previous_inst_id - 1

               instance_index := instance_index + 1;

               --  !  instanceRef referenceId manually added to iK without it
               put_line ("reference id" & instance_ref.referenceId'image);
               put_line ("instance id" & inst_index'image);
               --put_line ("instances l " & ob.instances.length'image);

               instance.referenceId := instance_ref.referenceId;
               instance.instanceId := inst_index;

               case itag_behav is
                  when inst_id => instance.instanceTag := inst_index;
                     --  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
                     --  !! this is not in order, issue? do instance tags also skip
                     --     values when some inst are only entities?
                     --
                     --  !!  objects.ens does not have itag
                     -- 
                  when same => instance.instanceTag := 53124;

                  when inc  => instance.instanceTag := itag_val;
                               itag_val := itag_val + 1;

                  when dec  => instance.instanceTag := itag_val;
                               itag_val := itag_val - 1;
               end case;

               matrix4_3'read (istream, instance.transform);
               rgba'read (istream, instance.color);

               if iK /= rdg then
               --  d2, f1_others. f1_2010
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

            --  ! test if number of instances read (instance_index) is same as
            --    number of instances iref has
            pragma assert (instance_ref.numInstances = instance_index);
            instance_index := 0;

            new_line (1);

         end loop;  -- instanceRef loop

      end if;


      put_line ("act total instance" & ob.act_total_instances'image & "   instance.length" & ob.instances.length'image);
      pragma assert (ob.act_total_instances = int32 (ob.instances.length));

      --  !  sort referenceId <
      --  !   > too?
      if sort_by_iref then
         iv_sorting.sort (ob.instances);
         put_line ("SORT");
      end if;


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

         ob.emitters.append (emitter);
      end loop;


      put_line ("ifd index" & sio.positive_count'image (sio.index (ifd) - 1));

      pragma assert (ui32 (sio.index (ifd)) - 1 =
        ob.instance_refs.first_element.fileNameOffset,
          "first fileNameOffset does not match ifd index");

   end read;




   procedure write (ob : in out o_b_type) is

      use type ada.containers.count_type;

      --oK : gm renames ob.oK;
      ofd : sio.file_type renames ob.ofd;
      ostream: sio.stream_access renames ob.ostream;

      --  actual num instances accumulate
      act_num_instances_accum : int32 := 0;
      --  ! offset accumulate
      offset_accum : int32 := 0;


      instance_nums : array (0 .. ob.instance_refs.last_index) of int32 :=
        (others => 0);

      --inst_index : int32 := 0;


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
               put_line ("ir sponsor " & instance_ref.sponsor'image);
               int32'write (ostream, instance_ref.sponsor);  --  default 0
               int32'write (ostream, instance_ref.prebakedShadows); --  default 0


               --  !  instanceTag different from instanceid?
               --  !  ds track?
               --  !  other d2 track?
               --   !  use numInstance for maxInstances? use act num inst for totalInstances?
               --  !  sponsor 0?
               --  !  color?

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
               if ik in d3 .. dr then
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
               if ik in d3 .. dr then
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


      --  ! how to check if instances in d3 .. dr in order?

      for instance of ob.instances loop

         put_line ("inst id" & instance.instanceId'image);
         put_line ("r id" & instance.referenceId'image);
         instance_nums (instance.referenceId) :=
           instance_nums (instance.referenceId) + 1;


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

      --  ! checks if number of inst written per iref matches numInstances of iref
      for iref_index in instance_nums'range loop
         declare
            irr : instanceRef_vectors.reference_type :=
              ob.instance_refs.reference (iref_index);
         begin
            put_line ("act nI" & irr.numInstances'image &
              "    written nI" & instance_nums (iref_index)'image);
            pragma assert (irr.numInstances = instance_nums (iref_index));
         end;
      end loop;

      <<skip_instance_ref>>


      --   dependentRef

      put_line ("dependent ref");
      put_line ("dependent ref count (li) " & ob.dependent_refs.last_index'image);
      put_line ("dependent ref count (length)" & ob.dependent_refs.length'image);
      put_line ("iK " & iK'image & "  oK " & oK'image);
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
      put_line ("iK " & iK'image & "  oK " & oK'image);

      if oK in d3 .. dr and ob.dependent_instances.length > 0 then
         put_line ("writing dependent inst");
         for dependent_instance of ob.dependent_instances loop
            dependentInstance'write (ostream, dependent_instance);
         end loop;
      end if;


      --  pathAnim

      put_line ("path anim");
      put_line ("path anim count " & ob.dependent_refs.last_index'image);
      put_line ("iK " & iK'image & "  oK " & oK'image);
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
      put_line ("iK " & iK'image & "  oK " & oK'image);
      if oK in d3 .. dr and ob.emitters.length > 0 then
         put_line ("writing emitter");
         for emitter of ob.emitters loop
            ob.so_info.append ((sio.index (ofd), emitter.nameOffset, sok_emitter_Name));
            emitter_type'write (ostream, emitter);
         end loop;
      end if;

      put_line ("ofd index" & sio.index (ofd)'image);

   end write;





   procedure update_string_offsets (ob : in out o_b_type) is

      --  !  all os below  0 based (- 1)

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

      --  forced_ornament_string
      fos_offset : constant int32 := ofd_sa_start + int32 (sa_size);

      --  !  all_strings?
      i_string_area : string (1 .. sa_size);


   begin

      if iK = oK
      or
        (iK in d2 | f1_others and
         oK in d2 | f1_others)
      or
        (iK in ga | dr and
         oK in ga | dr)
      then
         pragma assert (sa_diff = 0);
      end if;

      --  !  all string copied to output
      string'read (ob.istream, i_string_area);
      string'write (ob.ostream, i_string_area);

      pragma assert (fos_offset = int32 (sio.index (ob.ofd)) - 1);
      if force_ornament then
         put_line ("fos """ & fo_str (1 .. fo_str_l) & """");
         string'write (ob.ostream, fo_str (1 .. fo_str_l));
         --free (ob.fo_str'pool_address);
      end if;

      put_line ("sa difference " & sa_diff'image);

      for info of ob.so_info loop

        if so_profiles (oK) (info.kind) = true then

           put_line ("oK has " & info.kind'image);

           if info.value /= ui32'last and info.value /= 0 then

              sio.set_index (ob.ofd, info.offset_ol);

              if force_ornament and then info.kind = sok_iref_fileName then
                 int32'write (ob.ostream, fos_offset);
              else
                 int32'write (ob.ostream, int32 (info.value) + sa_diff);
              end if;

           else
              put_line ("offset not used by ik");
           end if;

           --   ! offsets of later str not correct if one ib are removed?

           --  !  can write dummy data/still write str if going to game without?

           --  !  can leave out if from game without?

          --  ! elsif so_profiles (iK) (info.kind) = true then
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



--    procedure update_ens (ob : in out o_b_type) is
-- 
--       tbei_tag : constant string := "<TEMPLATEBASICENTITYINSTANCE";
--       tei_tag : constant string := "<TEMPLATEENTITYINSTANCE";
--       tt_tag : constant string := "<TEMPLATETRANSFORM>";
-- 
--       line : string (1 .. 500);
--       last : natural;
-- 
--    begin
--       loop
--          get_line (ob.ens_ifd, line, last);
--          --  !!  last 0
--          if line (tbei_tag'range) = tbei_tag then
--             put_line (tbei_tag);
--             --  ! next inst
--          elsif line (tei_tag'range) = tei_tag then
--             put_line (tei_tag);
--          end if;
-- 
--          --  ! eof
--          --  !  end of instances?
--       end loop;
--    end update_ens;


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



   type parse_arg_access is
     access function (av : in string; i : in positive) return boolean;

   type cli_argument_type is record
      required : boolean;
      switch : string_access;
      has_value : boolean;
      placeholder_val : string_access;
      description : string_access;
      parse : parse_arg_access;
   end record;

   type argument_array is array (positive range <>) of cli_argument_type;


   k_count : natural := 0;
   function parse_k_arg (s : in string; i : in positive) return boolean is
      procedure put_line (s : in string) renames ada.text_io.put_line;
   begin
      if s = "-ik" then
         iK := gm'value (cli.argument (i + 1));
         k_count := k_count + 1;

      elsif s = "-ok" then
         oK := gm'value (cli.argument (i + 1));
         k_count := k_count + 1;
      end if;
      return true;
   exception
      when constraint_error =>
         put_line ("""" & cli.argument (i + 1) & """ invalid format");
         return false;
   end parse_k_arg;


   function parse_itag_arg (av : in string; index : positive) return boolean is

      procedure put_line (s : in string) renames ada.text_io.put_line;

      function is_valid_num (s : string) return boolean is
      begin
         for c of s loop
            if c not in '0' .. '9' then
               return false;
            end if;
         end loop;
         return true;
      end is_valid_num;

   begin
      if index + 1 > cli.argument_count then
         put_line ("missing value for -itag");
      else
         if itag_option'valid_value (cli.argument (index + 1)) then
            itag_behav := itag_option'value (cli.argument (index + 1));
            return true;
         else
            put_line ("invalid value for -itag");
            for val in itag_option'range loop
               put_line (val'image);
            end loop;
         end if;
      end if;
      return false;
   end parse_itag_arg;

   function parse_iref_sort_arg (av : in string; index : positive) return boolean is
   begin
      sort_by_iref := true;
      return true;
   end parse_iref_sort_arg;

   function parse_v_arg (av : in string; index : positive) return boolean is
   begin
      verbose := true;
      return true;
   end parse_v_arg;

   function parse_fo_arg (av : in string; index : positive) return boolean is
      procedure put_line (s : in string) renames ada.text_io.put_line;
   begin
      if index + 1 > cli.argument_count then
         put_line ("missing name string for -fo");
         return false;
      end if;

      force_ornament := true;

      declare
         s : constant string := cli.argument (index + 1);
      begin
         if s'length > fo_str'length then
            put_line ("fo string too long");
            return false;
         end if;
         fo_str_l := s'length + 1;
         fo_str (1 .. s'last + 1) := s & ascii.nul;
      end;
      return true;
   end parse_fo_arg;


   --  !  forward declaration because av_a has to be in scope of show_help
   procedure show_help;


   function parse_h_arg (av : in string; index : positive) return boolean is
   begin
      show_help;
      return false;
   end parse_h_arg;



   --  arguments
   --
   --    name tree


   av_a : argument_array :=
     ((required => true,
       switch   => +"-ik",  --  ! from?
       has_value => true,
       placeholder_val => +"<input kind>", --+"<input type>",
       description => +"format of input file",
       parse => parse_k_arg'access),

      (required => true,
       switch   => +"-ok",  --  ! to?
       has_value => true,
       placeholder_val => +"<output kind>",
       description => +"format of output file",
       parse => parse_k_arg'access),

      (required => false,
       switch   => +"-itag",
       has_value => true,
       placeholder_val => +"<same | inc | dec | inst_id>",
       description => +"behavior of setting instance tag when missing from ik",
       parse => parse_itag_arg'access),

      (required => false,
       switch   => +"-iref_sort",
       has_value => false,
       placeholder_val => +"",
       description => +"sort inst by iref id",
       parse => parse_iref_sort_arg'access),

      (required => false,
       switch   => +"-fo",
       has_value => false,
       placeholder_val => +"<ornament name>",
       description => +"force all instances to use ornament <name>",
       parse => parse_fo_arg'access),

      (required => false,
       switch   => +"-v",
       has_value => false,
       placeholder_val => +"",
       description => +"print what is happening",
       parse => parse_k_arg'access),

      (required => false,
       switch   => +"-h",
       has_value => false,
       placeholder_val => +"",
       description => +"show help message",
       parse => parse_h_arg'access),

      (required => true,
       switch   => +"",
       has_value => true,
       placeholder_val => +"<file.bin>",
       description => +"path to track route bin file",
       parse => null)
       );

   function parse_if_arg (arg_v : in string; arg_i : in positive) return boolean is
   begin
      for arg of av_a loop
         if arg.switch.all = arg_v then
            return arg.parse (arg_v, arg_i);
         end if;
      end loop;
      return false;
   end parse_if_arg;

   procedure show_help is
      procedure put_line (s : in string) renames ada.text_io.put_line;
   begin
      put_line ("usage: " & cli.command_name
        & " [options] -ik <input format kind> -ok <output format kind> <file>");
      put_line ("[ ] = optional, < > = required, | = or");

      put_line ("formats kinds (d2 = f1_others, ga = dr):");
      for g in gm'range loop
         put_line ("  " & g'image);
      end loop;

      put_line ("options:");
      for a of av_a loop
         if not a.required or else a.switch.all'length /= 0 then
            put_line ("  " & a.switch.all & " " & a.placeholder_val.all
              & ": " & a.description.all);
         end if;
      end loop;
   end show_help;


   kind : bin_kind;

   iformat : gm;
   oformat : gm;

   version_num : int32;
   second_4_bytes : float;

   ob : o_b_type;


begin
--    put_line (system.address_image (gnat_argv));
--    return;

   --put (312.199999999, aft => 9, exp => 0); new_line;
   --   312.314453125
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

   if arg_count = 0 or else cli.argument (1) = "-h" then
      show_help;
      return;

   elsif arg_count < 5 then
      put_line ("not enough arguments");
      show_help;
      return;

   end if;


   --  file arg check
   if not  dir.exists (cli.argument (arg_count)) or else
      not (dir.kind   (cli.argument (arg_count)) = dir.ordinary_file)
   then
      put_line ("""" & cli.argument (arg_count) & """ not a file");
      return;
   end if;


   --  options

   for arg_i in 1 .. arg_count - 1 loop
      if parse_if_arg (cli.argument (arg_i), arg_i) = false then
         --  ! parse fail or arg causes to exit early
         return;
      end if;
   end loop;

   if k_count /= 2 then
      put_line ("specify formats with ""-ik"" and ""-oK""");
      return;
   end if;


--    for file_arg in 5 .. cli.argument_count loop
--       if not  dir.exists (cli.argument (file_arg)) or else
--          not (dir.kind   (cli.argument (file_arg)) = dir.ordinary_file)
--       then
--          put_line ("""" & cli.argument (file_arg) & """ not a file");
--          return;
--       end if;
--    end loop;


   --  format kind
--    if (iK < d3 and oK >= d3) and then
--       cli.argument_count < 6
--    then
--       put_line ("path to input objects.ens needed for older to newer");
--       return;
-- 
   if iK = oK or
     (iK in d2 | f1_others and
      oK in d2 | f1_others)
   then
      put_line ("formats are same");
   end if;


   --  o
   sio.open (ob.ifd, sio.in_file, cli.argument (arg_count));
   sio.create (ob.ofd, sio.out_file, "output_test.bin");

   --  ens
--    if cli.argument_count >= 6 then
--       open (ob.ens_ifd, in_file, cli.argument (6));
--       create (ob.ens_ofd, out_file, "output_test.ens");
-- 
--       declare
--          xml_id : constant string := "<?xml";
--          b : string (1 .. 5);
--       begin
--          get (ob.ens_ifd, b);
--          if b /= xml_id then
--             put_line ("""" & cli.argument (6) & """ not xml file");
--             put_line ("first 5 char were """ & b & """");
--             return;
--          end if;
--          set_col (ob.ens_ifd, 1);
--       end;
-- 
--    end if;

   --  
--    sio.open (ifile, sio.in_file, cli.argument (1));
--    sio.create (ofile, sio.out_file, "output_test");

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

   --put_line ("na " & system.address_image (system.null_address));
   --  !!  causes internal compiler rerror
   --free (ob.fo_str.all'pool_address);

   sio.close (ob.ifd);
   sio.close (ob.ofd);
end bin_test;
