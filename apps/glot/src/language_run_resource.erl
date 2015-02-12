-module(language_run_resource).
-export([
    init/3,
    rest_init/2,
    allowed_methods/2,
    content_types_accepted/2,
    content_types_provided/2,
    %is_authorized/2,
    accept_post/2
]).

-define(INVALID_JSON, <<"Invalid json">>).


init(_Transport, _Req, _Opts) ->
    {upgrade, protocol, cowboy_rest}.

rest_init(Req, []) ->
    {ok, Req, []}.

allowed_methods(Req, State) ->
    Methods = [<<"GET">>, <<"POST">>],
    {Methods, Req, State}.

content_types_accepted(Req, State) ->
    Handlers = [
        {{<<"application">>, <<"json">>, '*'}, accept_post}
    ],
    {Handlers, Req, State}.

content_types_provided(Req, State) ->
    Handlers = [
        {{<<"application">>, <<"json">>, '*'}, noop}
    ],
    {Handlers, Req, State}.

%is_authorized(Req, State) ->
%    case http_auth:is_authorized_user(Req, State) of
%        ok -> {true, Req};
%        Unauthorized -> Unauthorized
%    end.

accept_post(Req, State) ->
    {ok, Body, Req2} = cowboy_req:body(Req),
    case jsx:is_json(Body) of
        true ->
            run_code(Body, Req2, State);
        false ->
            Payload = jsx:encode([{message, ?INVALID_JSON}]),
            {ok, Req3} = cowboy_req:reply(400, [], Payload, Req2),
            {halt, Req3, State}
    end.

run_code(Data, Req, State) ->
    lager:info("Data: ~p", [Data]),
    Result = language_run:run(<<"python">>, <<"latest">>, Data),
    Req2 = cowboy_req:set_resp_body(jsx:encode(Result), Req),
    {true, Req2, State}.

%decode_body(F, Req, State) ->
%    {ok, Body, Req2} = cowboy_req:body(Req),
%    case jsx:is_json(Body) of
%        true ->
%            Data = jsx:decode(Body),
%            F(Data, Req2, State);
%        false ->
%            Payload = jsx:encode([{message, ?INVALID_JSON}]),
%            {ok, Req3} = cowboy_req:reply(400, [], Payload, Req2),
%            {halt, Req3, State}
%    end.
