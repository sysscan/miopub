local Game = game;
local Players = Game : GetService( "Players" );
local HttpService = Game : GetService( "HttpService" );
local Player = Players.LocalPlayer;
local Invite = "https://discord.gg/9W3tDNjWan";
local InviteCode = "9W3tDNjWan";
local Scope = getfenv( );
local Environments = { Scope };
local PCall = pcall;
local Type = type;
local RawGet = rawget;
local TaskSpawn = task.spawn;
local TaskDelay = task.delay;
local InstanceNew = Instance.new;
local Color3FromRGB = Color3.fromRGB;
local UDim2FromOffset = UDim2.fromOffset;

if ( not Player ) then
    return;
end

local Parent = Player : WaitForChild( "PlayerGui", 15 );
if ( not Parent ) then
    return;
end

local function Resolve( Name: string ): any
    for _, Environment in Environments do
        local Value = Environment[ Name ];
        if ( Value ~= nil ) then
            return Value;
        end
    end
    return nil;
end

local GetGlobalEnvironment = Resolve( "getgenv" );
if ( Type( GetGlobalEnvironment ) == "function" ) then
    local Success, Environment = PCall( GetGlobalEnvironment );
    if ( Success and Type( Environment ) == "table" and Environment ~= Scope ) then
        table.insert( Environments, Environment );
    end
end

local Request = Resolve( "request" ) or Resolve( "http_request" );
if ( Type( Request ) ~= "function" ) then
    local Http = Resolve( "http" );
    local Syn = Resolve( "syn" );
    Request = ( Type( Http ) == "table" and RawGet( Http, "request" ) )
        or ( Type( Syn ) == "table" and RawGet( Syn, "request" ) );
end
local Clipboard = Resolve( "setclipboard" ) or Resolve( "toclipboard" );

local Previous = Parent : FindFirstChild( "MioAdvertisement" );
if ( Previous ) then
    Previous : Destroy( );
end

local function Create( Class: string, Properties: { [string]: any }, Target: Instance ): Instance
    local Object = InstanceNew( Class );
    for Name, Value in Properties do
        Object[ Name ] = Value;
    end
    Object.Parent = Target;
    return Object;
end

local Screen = Create( "ScreenGui", {
    Name = "MioAdvertisement", ResetOnSpawn = false, IgnoreGuiInset = true,
    DisplayOrder = 100, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, Parent );
local Panel = Create( "Frame", {
    AnchorPoint = Vector2.new( 0.5, 0.5 ), Position = UDim2.fromScale( 0.5, 0.5 ),
    Size = UDim2.new( 0.9, 0, 0, 306 ), BackgroundColor3 = Color3FromRGB( 22, 20, 26 ), BorderSizePixel = 0,
}, Screen );
Create( "UISizeConstraint", { MaxSize = Vector2.new( 460, 306 ) }, Panel );
Create( "UICorner", { CornerRadius = UDim.new( 0, 14 ) }, Panel );
Create( "UIStroke", { Color = Color3FromRGB( 237, 116, 174 ), Transparency = 0.35 }, Panel );

Create( "TextLabel", {
    Position = UDim2FromOffset( 24, 20 ), Size = UDim2.new( 1, -48, 0, 34 ),
    BackgroundTransparency = 1, Text = "Welcome to Mio", TextColor3 = Color3FromRGB( 237, 116, 174 ),
    Font = Enum.Font.GothamBold, TextSize = 26, TextXAlignment = Enum.TextXAlignment.Left,
}, Panel );
Create( "TextLabel", {
    Position = UDim2FromOffset( 24, 62 ), Size = UDim2.new( 1, -48, 0, 60 ),
    BackgroundTransparency = 1,
    Text = "This advertisement opens our Discord. Join to get the official hub loader, access instructions and game updates.",
    TextColor3 = Color3FromRGB( 224, 216, 230 ), Font = Enum.Font.Gotham, TextSize = 14,
    TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
}, Panel );
local Link = Create( "TextBox", {
    Position = UDim2FromOffset( 24, 130 ), Size = UDim2.new( 1, -48, 0, 38 ),
    BackgroundColor3 = Color3FromRGB( 34, 30, 39 ), Text = Invite, ClearTextOnFocus = false,
    TextEditable = false, TextColor3 = Color3FromRGB( 240, 233, 244 ), Font = Enum.Font.Gotham, TextSize = 14,
}, Panel );
Create( "UICorner", { CornerRadius = UDim.new( 0, 8 ) }, Link );
local Status = Create( "TextLabel", {
    Position = UDim2FromOffset( 24, 176 ), Size = UDim2.new( 1, -48, 0, 36 ),
    BackgroundTransparency = 1, Text = "Opening the Discord invite...", TextColor3 = Color3FromRGB( 195, 179, 202 ),
    Font = Enum.Font.Gotham, TextSize = 12, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
}, Panel );
local Open = Create( "TextButton", {
    Position = UDim2FromOffset( 24, 222 ), Size = UDim2.new( 0.5, -30, 0, 40 ),
    BackgroundColor3 = Color3FromRGB( 237, 116, 174 ), Text = "Open Discord",
    TextColor3 = Color3FromRGB( 24, 19, 25 ), Font = Enum.Font.GothamBold, TextSize = 14,
}, Panel );
Create( "UICorner", { CornerRadius = UDim.new( 0, 8 ) }, Open );
local Copy = Create( "TextButton", {
    Position = UDim2.new( 0.5, 6, 0, 222 ), Size = UDim2.new( 0.5, -30, 0, 40 ),
    BackgroundColor3 = Color3FromRGB( 47, 38, 51 ), Text = "Copy invite",
    TextColor3 = Color3FromRGB( 240, 233, 244 ), Font = Enum.Font.GothamBold, TextSize = 14,
}, Panel );
Create( "UICorner", { CornerRadius = UDim.new( 0, 8 ) }, Copy );
local Close = Create( "TextButton", {
    Position = UDim2FromOffset( 24, 273 ), Size = UDim2.new( 1, -48, 0, 22 ),
    BackgroundTransparency = 1, Text = "Close", TextColor3 = Color3FromRGB( 170, 156, 181 ),
    Font = Enum.Font.Gotham, TextSize = 12,
}, Panel );

local Busy = false;
local Attempt = 0;

local function Alive( ): boolean
    return Screen.Parent ~= nil;
end

local function OpenDiscord( )
    if ( Busy or not Alive( ) ) then
        return;
    end
    if ( Type( Request ) ~= "function" ) then
        Status.Text = "Automatic opening is unavailable here. Copy the invite or open it in your browser.";
        return;
    end
    Busy = true;
    Attempt += 1;
    local CurrentAttempt = Attempt;
    Open.Text = "Opening...";
    Status.Text = "Opening the Discord invite...";
    TaskDelay( 6, function( )
        if ( not Alive( ) or CurrentAttempt ~= Attempt or not Busy ) then
            return;
        end
        Attempt += 1;
        Busy = false;
        Open.Text = "Try again";
        Status.Text = "Couldn't confirm Discord opened. Copy the invite if needed.";
    end );
    TaskSpawn( function( )
        if ( not Alive( ) or CurrentAttempt ~= Attempt ) then
            return;
        end
        local Success, Response = PCall( function( )
            return Request( {
                Url = "http://127.0.0.1:6463/rpc?v=1", Method = "POST",
                Headers = { [ "Content-Type" ] = "application/json", [ "Origin" ] = "https://discord.com" },
                Body = HttpService : JSONEncode( {
                    cmd = "INVITE_BROWSER", args = { code = InviteCode }, nonce = HttpService : GenerateGUID( false ),
                } ),
            } );
        end );
        if ( not Alive( ) or CurrentAttempt ~= Attempt ) then
            return;
        end
        Busy = false;
        Open.Text = "Open Discord";
        if ( Success and Type( Response ) == "table" and tonumber( Response.StatusCode ) == 200 ) then
            Status.Text = "Invite requested. Check Discord to finish joining and get the official loader.";
            return;
        end
        Status.Text = "Couldn't open Discord here. Copy the invite or open it in your browser.";
    end );
end

local function CopyInvite( )
    if ( not Alive( ) ) then
        return;
    end
    if ( Type( Clipboard ) == "function" ) then
        local Success, Result = PCall( Clipboard, Invite );
        if ( Success and Result ~= false ) then
            Status.Text = "Invite copied. Paste it into Discord or your browser.";
            return;
        end
    end
    Link : CaptureFocus( );
    Link.SelectionStart = 1;
    Link.CursorPosition = #Invite + 1;
    Status.Text = "Select the invite above and copy it into Discord or your browser.";
end

Open.Activated : Connect( OpenDiscord );
Copy.Activated : Connect( CopyInvite );
Close.Activated : Connect( function( )
    Attempt += 1;
    Screen : Destroy( );
end );
TaskDelay( 1, OpenDiscord );
