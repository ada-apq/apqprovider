------------------------------------------------------------------------------
--                                                                          --
--                          APQ DATABASE BINDINGS                           --
--                                                                          --
--                           Connection Provider                            --
--                                                                          --
--                                 S p e c                                  --
--                                                                          --
--            Copyright (C) 2009 .. 2011 KOW Framework Project              --
--                                                                          --
--                                                                          --
-- APQ is free software;  you can  redistribute it  and/or modify it under  --
-- terms of the  GNU General Public License as published  by the Free Soft- --
-- ware  Foundation;  either version 2,  or (at your option) any later ver- --
-- sion.  APQ is distributed in the hope that it will be useful, but WITH-  --
-- OUT ANY WARRANTY;  without even the  implied warranty of MERCHANTABILITY --
-- or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License --
-- for  more details.  You should have  received  a copy of the GNU General --
-- Public License  distributed with APQ;  see file COPYING.  If not, write  --
-- to  the Free Software Foundation,  59 Temple Place - Suite 330,  Boston, --
-- MA 02111-1307, USA.                                                      --
--                                                                          --
-- As a special exception,  if other files  instantiate  generics from this --
-- unit, or you link  this unit with other files  to produce an executable, --
-- this  unit  does not  by itself cause  the resulting  executable  to  be --
-- covered  by the  GNU  General  Public  License.  This exception does not --
-- however invalidate  any other reasons why  the executable file  might be --
-- covered by the  GNU Public License.                                      --
--                                                                          --
------------------------------------------------------------------------------



--------------
-- Ada 2005 --
--------------
with Ada.Exceptions;

-------------------
-- KOW Framework --
-------------------
with KOW_Config;
with KOW_Config.Generic_Util;
with KOW_Config.Util;
with KOW_Lib.Log;

---------
-- APQ --
---------
with APQ;

package body APQ_Provider is

	---------
	-- Log --
	---------

	Logger : KOW_Lib.Log.Logger_Type := 
			KOW_Lib.Log.Get_Logger( "APQ_Provider" );
	
	procedure Log(
			Message : in String;
			Level : KOW_Lib.Log.Log_Level := KOW_lib.Log.Level_Info
		) is
	begin
		KOW_lib.Log.Log(
				Logger	=> Logger,
				Level	=> Level,
				Message	=> Message
			);
	end Log;

	----------------------------
	-- The Connection Factory --
	----------------------------

	function Generic_Connection_Factory( Config : in KOW_Config.Config_File_Type ) return APQ.Connection_Ptr is
		use APQ;
		use KOW_Config;

		Connection : APQ.Connection_Ptr := new Connection_Type;

		function H( Key :in String ) return Boolean is
		begin
			return Contains( Config, Key );
		end H;
	begin
		-- Case :: 
		if H( "case" ) then
			Set_Case(
					Connection.All,
					APQ.SQL_Case_Type'Value(
						Default_Value( Config, "case" )
						)
				);
		end if;

		-- Instance :: 
		if H( "instance" ) then
			Set_Instance(
					C		=> Connection.All,
					Instance	=> Default_Value( Config, "instance" )
				);
		end if;

		-- Host Name ::
		if H( "host_name" ) then
			Set_Host_Name(
					C		=> Connection.All,
					Host_Name	=> Default_Value( Config, "host_name" )
				);
		end if;

		-- Host Address ::
		if H( "host_address" ) then
			Set_Host_Address(
					C		=> Connection.All,
					Host_Address	=> Default_Value( Config, "host_address" )
				);
		end if;

		-- TCP Port ::
		if H( "port" ) then
			Set_Port(
					C		=> Connection.All,
					Port_Number	=> Util.Integers.Default_Value( Config, "port" )
				);
		end if;

		-- Unix Port ::
		if H( "unix_port" ) then
			Set_Port(
					C		=> Connection.all,
					Port_Name	=> Default_Value( Config, "unix_port" )
				);
		end if;

		-- DB Name ::
		if H( "db_name" ) then
			Set_DB_Name(
					C		=> Connection.all,
					DB_Name		=> Default_Value( Config, "db_name" )
				);
		end if;

		-- User ::
		if H( "user" ) then
			Set_User(
					C		=> Connection.all,
					User		=> Default_Value( Config, "user" )
				);
		end if;

		-- Password ::
		if H( "password" ) then
			Set_Password(
					C		=> Connection.all,
					Password	=> Default_Value( Config, "password" )
				);
		end if;

		-- Rollback on Finalize ::
		if H( "rollback_on_finalize" ) then
			Set_Rollback_On_Finalize(
					C		=> Connection.all,
					Rollback	=> Util.Booleans.Default_Value( Config, "rollback_on_finalize" )
				);
		end if;

		return Connection;
	end Generic_Connection_Factory;



	protected body Factory_Registry is
		procedure Register_Factory( Engine : in APQ.Database_Type; Factory : in Connection_Factory_Type ) is
			-- set a factory..
			-- if Factory = null, it's the same as "unsetting" it.
		begin
			Factories( Engine ) := Factory;
		end Register_Factory;

		function Get_Factory( Engine : in APQ.Database_Type ) return Connection_Factory_Type is
			-- get a factory.
			-- if it's null, raise NO_FACTORY exception
		begin
			if Factories( Engine ) = null then
				raise No_Factory with APQ.Database_Type'Image( Engine );
			end if;

			return Factories( Engine );
		end Get_Factory;
	end Factory_Registry;



	-----------------------------
	-- The Connection Instance --
	-----------------------------



	protected body Connection_Instance_Type is
		-- the Connection Instance is the type that actually handles each connection individually.
		--
		-- it not only represents the connection, but is also responsible for loading and
		-- connecting into the database backend.

		procedure Run(
				Connection_Runner : not null access procedure( Connection : in out APQ.Root_Connection_Type'Class )
			) is
			-- make sure the connection is active and then run Connection_Runner
			-- NOTE: if APQ.Not_Connected is raised inside the Connection_Runner procedure
			-- tries to reconnect and call it again... if the exception is raised by the 2nd time,
			-- it's reraised.


			procedure Run is
			begin
				if not APQ.Is_Connected( My_Connection.all ) then
					APQ.Connect( My_Connection.all );
				end if;

				Connection_Runner.all( My_Connection.all );

				if not Keepalive then
					APQ.Disconnect( My_Connection.all );
				end if;
			end Run;
			use APQ;
		begin
			if My_Connection = NULL then
				raise PROGRAM_ERROR with "you need to run setup first..";
			end if;

			Run;
		exception
			when APQ.NOT_CONNECTED =>
				APQ.Connect( My_Connection.all, False );
				Run;
		end Run;

		procedure Setup( Config : in KOW_Config.Config_File_Type ) is
			-- setup the database connection for this instance

			Engine : APQ.Database_Type;
			Engine_Str : String := KOW_Config.Default_Value( Config, "engine" );
		begin
			Keepalive := KOW_Config.Util.Booleans.Default_Value( Config, "keepalive", True );
			begin
				Engine := APQ.Database_Type'Value( "Engine_" & Engine_Str );
			exception
				when CONSTRAINT_ERROR =>
					raise UNKNOWN_ENGINE with Engine_Str;
			end;

			My_Connection := Factory_Registry.Get_Factory( Engine ).all( Config );
		end Setup;


		procedure Set_Id( Id : in Positive ) is
		begin
			My_Id := Id;
		end Set_Id;

		function Get_Id return Positive is
		begin
			return My_Id;
		end Get_Id;
	end Connection_Instance_Type;


	------------------------------
	-- Connection Provider Type --
	------------------------------



	protected body Connection_Provider_Type is 
		procedure Acquire_Instance( Instance : out Connection_Instance_Ptr ) is
			-- get an instance, locking it.
			-- if no unlocked instance is available, raise Out_Of_Instances

			Inst : Connection_Instance_Type;
			i    : Integer := Last_Acquired + 1;
		begin

			if i > My_Instances'Last then
				i := My_Instances'First;
			end if;

			while i /= Last_Acquired loop
				Log( "Trying instance #" & Positive'Image( i ) & " of " & Positive'Image( My_Instances'Length ), KOW_Lib.Log.Level_Debug );
				if not My_In_Use( i ) then
					Log( "Instance acquired", KOW_Lib.Log.Level_Debug );
					My_In_Use( i ) := True;
					Instance := My_Instances( i );
					Last_Acquired := i;
					return;
				else
					if i = My_Instances'Last then
						i := My_Instances'First;
					else
						i := i + 1;
					end if;
				end if;
			end loop;

			raise Out_Of_Instances with "no instance free to use at this moment..";
		end Acquire_Instance;
				


		procedure Release_Instance( Instance : in Connection_Instance_Ptr ) is
			-- release an instance, unlocking it.
		begin
			My_In_Use( Instance.Get_Id ) := False;
		end Release_Instance;

		procedure Setup( Config : in KOW_Config.Config_File_Type ) is
			My_Config : KOW_Config.Config_File_Type := Config;

		begin
			KOW_Config.Set_Section( My_Config, "apq_provider" );

			declare

				function From_String( Str : in String ) return KOW_Lib.Log.Log_Level is
				begin
					return KOW_Lib.Log.Log_Level'Value( "Level_" & Str );
				end From_String;

				package Log_Level_Util is new KOW_Config.Generic_Util(
											Element_Type	=> KOW_Lib.Log.Log_Level,
											From_String	=> From_String,
											To_String	=> KOW_Lib.Log.Log_Level'Image -- it's actually wrong but it's not used here
										);
				Engine_Cfgs	: KOW_Config.Config_File_Array :=
							KOW_Config.Extract_Array( Config, "apq_provider.engines" );
				Count		: Integer := 1;
				Current_Length	: Integer;
			begin

				Log_Level := Log_Level_Util.Default_Value( Config, "log_level", KOW_Lib.Log.Level_Nul );
				for i in Engine_Cfgs'First .. Engine_Cfgs'Last loop
					Count := Count + KOW_Config.Util.Integers.Default_Value( Engine_Cfgs( i ), "slots", 1 );
				end loop;

				if Count = 1 then
					raise CONSTRAINT_ERROR with "not enough engines in APQ_Provider Config " & KOW_Config.Get_File_Name( Config );
				else
					Count := Count - 1;
				end if;

				My_Instances := new Connection_Instance_Array_Type( 1 .. Count );
				My_In_Use := new Boolean_Array_Type( 1 .. Count );
				My_In_Use.all := ( others => FALSE );

				-- now we initialize the engines..

				Count := 1;
				
				for i in Engine_Cfgs'First .. Engine_Cfgs'Last loop
					Current_Length := KOW_Config.Util.Integers.Default_Value( Engine_Cfgs( i ), "slots", 1 );

					for j in 1 .. Current_Length loop
						Log( "Setting up instance #" & Positive'Image( Count ) );
						My_Instances( Count ) := new Connection_Instance_Type;
						My_Instances( Count ).Setup( Engine_Cfgs( i ) );
						My_Instances( Count ).Set_Id( Count );
						Count := Count + 1; -- we compute the current count..
					end loop;
				end loop;
			end;
		end Setup;

--	private
--		My_Instances : Connection_Instance_Array_Ptr;
	end Connection_Provider_Type;


	procedure Run(
			Provider		: in out Connection_Provider_Type;
			Connection_Runner	: not null access procedure( Connection : in out APQ.Root_Connection_Type'Class );
			Queue_On_OOI		: in     Boolean := True
		) is
		-- run the connection runner in an instance of the given provider.
		-- if queue_on_OOI, tries to run while Out_Of_Instance exception keeps
		-- getting raised

		Instance : Connection_Instance_Ptr;
	begin
		loop
			begin
				Provider.Acquire_Instance( Instance );
				Instance.Run( Connection_Runner );
				Provider.Release_Instance( Instance );
				exit;
			exception
				when E : Out_of_Instances =>
					Log( "All instances in use! If you get this message a lot, upgrade your DB structure", KOW_Lib.Log.Level_Error );
					if not Queue_on_OOI then
						Ada.Exceptions.Reraise_Occurrence( E );
					end if;
					delay 0.01;
					Log( "Delay ok..." );
				when E : others =>
					begin
						Provider.Release_Instance( Instance );
					exception
						when others =>
							Log( "Error release APQ Provider instance.", KOW_Lib.Log.Level_Error );
							exit;
					end;
					Ada.Exceptions.Reraise_Occurrence( E );
			end;
		end loop;

	end Run;


end APQ_Provider;
