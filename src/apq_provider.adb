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

package body APQ_Provider is


	----------------------------
	-- The Connection Factory --
	----------------------------

	function Generic_Connection_Factory( Config : in Aw_Config.Config_File ) return APQ.Connection_Ptr is
		Conn : APQ.Connection_Ptr := null;
	begin
		return Conn;
	end Generic_Connection_Factory;



	protected body Connection_Instance_Type is
		procedure Run( Connection_Runner : in Connection_Runner_Type ) is
		begin
			Connection_Runner.all( My_Connection.all );
		end Run;
	end Connection_Instance_Type;

	protected body Connection_Provider_Type is 



		procedure Get_Instance( Instance : in out Connection_Instance_Ptr ) is
		begin
			Instance := new Connection_Instance_Type;
		end Get_Instance;
	end Connection_Provider_Type;

	Prov : Connection_Provider_Type;
	Inst : Connection_Instance_Ptr;


	procedure My_Runner( Conn : in out APQ.Root_Connection_Type'Class ) is
		Query : APQ.Root_Query_Type'Class := APQ.New_Query( Conn );
	begin

		APQ.Execute( Query, Conn );
	end My_Runner;


begin
	Prov.Get_Instance( Inst );

	Inst.Run( My_Runner'Access );
	
end APQ_Provider;
