------------------------------------------------------------------------------
--                                                                          --
--                          APQ DATABASE BINDINGS                           --
--                                                                          --
--                           Connection Provider                            --
--                                                                          --
--                                 S p e c                                  --
--                                                                          --
--                  Copyright (C) 2009 Ada Works Project                    --
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

---------------
-- Ada Works --
---------------
with Aw_Config;
with Aw_Lib.Log;

---------
-- APQ --
---------
with APQ;

package APQ_Provider is


	----------------
	-- Exceptions --
	----------------

	No_Factory : Exception;
	-- when there is no driver registered for an engine
	
	Unknown_Engine : Exception;
	-- when there is no know engine of such type.


	Out_Of_Instances : Exception;
	-- when there is no more available instance


	----------------------------
	-- The Connection Factory --
	----------------------------


	
	type Connection_Factory_Type is access function( Config : in Aw_Config.Config_File ) return APQ.Connection_Ptr;
	-- it's the function used internally to create a new instance of a database.
	--
	-- not only memory allocation must be handled, but also the basic setup has to be performed.
	

	generic
		type Connection_Type is new APQ.Root_Connection_Type with private;
	function Generic_Connection_Factory( Config : in Aw_Config.Config_File ) return APQ.Connection_Ptr;
	-- to easy things, a generic function for the main database properties is defined.
	--
	-- the user can also setup his own function, but a new instance of this one should be enough for every case.

	
	type Connection_Factory_Array is array ( APQ.Database_Type'Range ) of Connection_Factory_Type;
	
	protected Factory_Registry is
		procedure Register_Factory( Engine : in APQ.Database_Type; Factory : in Connection_Factory_Type );
		-- set a factory..
		-- if Factory = null, it's the same as "unsetting" it.

		function Get_Factory( Engine : in APQ.Database_Type ) return Connection_Factory_Type;
		-- get a factory.
		-- if it's null, raise NO_FACTORY exception
	private
		Factories : Connection_Factory_Array;
	end Factory_Registry;



	-----------------------------
	-- The Connection Instance --
	-----------------------------


	protected type Connection_Instance_Type is
		-- the Connection Instance is the type that actually handles each connection individually.
		--
		-- it not only represents the connection, but is also responsible for loading and
		-- connecting into the database backend.


		procedure Run(
				Connection_Runner : not null access procedure( Connection : in out APQ.Root_Connection_Type'Class )
			);
		-- make sure the connection is active and then run Connection_Runner
		-- NOTE: if APQ.Not_Connected is raised inside the Connection_Runner procedure
		-- tries to reconnect and call it again... if the exception is raised by the 2nd time,
		-- it's reraised.


		procedure Setup( Config : in Aw_Config.Config_File );
		-- setup the database connection for this instance
	

		procedure Set_Id( Id : in Positive );
		function Get_Id return Positive;
		-- The ID is what the connection provider uses to control
		-- if it's in use or no.

	private
		Keepalive	: Boolean;
		-- should the connection be kept alive?
	
		My_Connection	: APQ.Connection_Ptr;
		-- the connection :D


		My_Id		: Positive;
	end Connection_Instance_Type;


	type Connection_Instance_Ptr is access Connection_Instance_Type;
	-- it's how we access the instances inside our code
	-- note that the connection instance type is a protected type. :)
	
	type Connection_Instance_Array_Type is array ( Positive range <> ) of Connection_Instance_Ptr;
	type Connection_Instance_Array_Ptr is access Connection_Instance_Array_Type;
	-- these types are used inside the connection provider type


	type Boolean_Array_Type is array( Positive range <> ) of Boolean;
	type Boolean_Array_Ptr is access Boolean_Array_Type;
	-- use to track used connection instance.

	------------------------------
	-- Connection Provider Type --
	------------------------------

	protected type Connection_Provider_Type is 
		procedure Acquire_Instance( Instance : out Connection_Instance_Ptr );
		-- get an instance, locking it.
		-- if no unlocked instance is available, raise Out_Of_Instances

		procedure Release_Instance( Instance : in Connection_Instance_Ptr );
		-- release an instance, unlocking it.


		procedure Setup( Config : in Aw_Config.Config_File );
		-- setup the connection provider and all it's instances.
	

	private
		Log_Level	: Aw_Lib.Log.Log_Level;
		My_Instances	: Connection_Instance_Array_Ptr;
		My_In_Use	: Boolean_Array_Ptr;
	end Connection_Provider_Type;

	type Connection_Provider_Ptr is access all Connection_Provider_Type;


	procedure Run(
			Provider		: in out Connection_Provider_Type;
			Connection_Runner	: not null access procedure( Connection : in out APQ.Root_Connection_Type'Class );
			Queue_On_OOI		: in     Boolean := True
		);

	-- run the connection runner in an instance of the given provider.
	-- if queue_on_OOI, tries to run while Out_Of_Instance exception keeps
	-- getting raised


end APQ_Provider;
