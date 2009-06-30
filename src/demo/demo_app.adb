with APQ;
with APQ_Provider;


procedure Demo_App is

	My_Provider : APQ_Provider.Connection_Provider_Type;
	-- The Connection_Provider_Type is a protected type that
	-- control all the database connections.

	My_Instance : APQ_Provider.Connection_Instance_Type;


	procedure Perform_Queries( Conn : in out APQ.Root_Connection_Type'Class ) is
		Query : APQ.Root_Query_Type'Class := APQ.New_Query( Conn );
	begin
		APQ.Prepare( Query, "SELECT NOW()" );
		-- set some values and stuff...
	end Perform_Queries;
begin


	My_Provider.Setup( "provider_name" );
	-- this will run Aw_Config routines to setup this connection provider. 

	My_Provider.Acquire_Instance( My_Instance );
	-- this setup an active connection represented by the
	-- APQ_Provider.Connection_Instance_Type.

	My_Instance.Run( Perform_Queries'Access );
	-- that's where all the database stuff happens.. :D

	My_Provider.Release_Instance( My_Instance );

end Demo_App;
	

	
