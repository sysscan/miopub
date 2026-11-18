local Message = "This loader has been retired. Get a key at https://pay.mwstack.dev and redeem it in the Discord.";
local Success = pcall( function( )
    game : GetService( "StarterGui" ) : SetCore( "SendNotification", { Title = "Mio", Text = "Loader retired. Get a key at pay.mwstack.dev", Duration = 15 } );
end );
warn( Message );
