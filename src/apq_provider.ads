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

---------
-- APQ --
---------
with APQ;

package APQ_Provider is


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



	-----------------------------
	-- The Connection Instance --
	-----------------------------

	type Connection_Runner_Type is not null access procedure( conn : in out APQ.Root_Connection_Type'Class );
	-- this is a procedure that's called by the Instance.Run() procedure.

	protected type Connection_Instance_Type is
		-- the Connection Instance is the type that actually handles each connection individually.
		--
		-- it not only represents the connection, but is also responsible for loading and
		-- connecting into the database backend.

		procedure Run( Connection_Runner : in Connection_Runner_Type );
		procedure Set_Connection( Connection : in APQ.Connection_Ptr );
	
	private
		My_Connection : APQ.Connection_Ptr;
	end Connection_Instance_Type;

	protected type Connection_Provider_Type is 
		procedure Get_Instance( Instance : in out Connection_Instance_Type );
	private
		My_Connection : APQ.Connection_Ptr;
	end Connection_Provider_Type;

end APQ_Provider;