
% https://www.decentlab.com/products/wind-speed-wind-direction-and-temperature-sensor-for-lorawan

-module(decentlab_decoder).
-define(PROTOCOL_VERSION, 2).
-export([decode/1, start/0]).

-define(SENSOR_DEFS,
  [
    #{
      length => 8,
      values => [
        #{
          name => <<"Wind speed">>,
          convert => fun(X) -> (lists:nth(0 + 1, X) - 32768) / 100 end,
          unit => <<"m⋅s⁻¹"/utf8>>
        },
        #{
          name => <<"Wind direction">>,
          convert => fun(X) -> (lists:nth(1 + 1, X) - 32768) / 10 end,
          unit => <<"°"/utf8>>
        },
        #{
          name => <<"Maximum wind speed">>,
          convert => fun(X) -> (lists:nth(2 + 1, X) - 32768) / 100 end,
          unit => <<"m⋅s⁻¹"/utf8>>
        },
        #{
          name => <<"Air temperature">>,
          convert => fun(X) -> (lists:nth(3 + 1, X) - 32768) / 10 end,
          unit => <<"°C"/utf8>>
        },
        #{
          name => <<"X orientation angle">>,
          convert => fun(X) -> (lists:nth(4 + 1, X) - 32768) / 10 end,
          unit => <<"°"/utf8>>
        },
        #{
          name => <<"Y orientation angle">>,
          convert => fun(X) -> (lists:nth(5 + 1, X) - 32768) / 10 end,
          unit => <<"°"/utf8>>
        },
        #{
          name => <<"North wind speed">>,
          convert => fun(X) -> (lists:nth(6 + 1, X) - 32768) / 100 end,
          unit => <<"m⋅s⁻¹"/utf8>>
        },
        #{
          name => <<"East wind speed">>,
          convert => fun(X) -> (lists:nth(7 + 1, X) - 32768) / 100 end,
          unit => <<"m⋅s⁻¹"/utf8>>
        }
      ]
    },
    #{
      length => 1,
      values => [
        #{
          name => <<"Battery voltage">>,
          convert => fun(X) -> lists:nth(0 + 1, X) / 1000 end,
          unit => <<"V"/utf8>>
        }
      ]
    }
  ]
).


decode(<<?PROTOCOL_VERSION, DeviceId:16,
         Flags:16/bitstring, Bytes/binary>> = Binary) when is_binary(Binary) ->
  Words = bytes_to_words(Bytes),
  maps:merge(#{<<"Protocol version">> => ?PROTOCOL_VERSION,
               <<"Device Id">> => DeviceId},
             sensor(Words, Flags, ?SENSOR_DEFS));
decode(HexStr) ->
  Binary = hex2bin(HexStr),
  decode(Binary).


start() ->
  io:format("~p~n", [decode("0208c900038009812b8014810880027fe8800880040bf5")]),
  io:format("~p~n", [decode("0208c900020bf5")]).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%% PRIVATE FUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

sensor(_Words, _Flags, []) -> #{};
sensor(Words, <<Flags:15, 0:1>>, [_Cur | Rest]) ->
  sensor(Words, <<0:1, Flags:15>>, Rest);
sensor(Words, <<Flags:15, 1:1>>,
       [#{length := Len, values := ValueDefs} | RestDefs]) ->
  {X, RestWords} = lists:split(Len, Words),
  Values = value(ValueDefs, X),
  RestSensors = sensor(RestWords, <<0:1, Flags:15>>, RestDefs),
  maps:merge(Values, RestSensors).


value([], _X) -> #{};
value([#{convert := Convert,
         name := Name} = ValueDef | RestDefs], X) ->
  Values = value(RestDefs, X),
  Value = #{<<"value">> => Convert(X)},
  Value2 = add_unit(Value, ValueDef),
  maps:put(Name, Value2, Values);
value([_NoConvert | RestDefs], X) -> value(RestDefs, X).


add_unit(Value, #{unit := Unit}) ->
  maps:put(<<"unit">>, Unit, Value);
add_unit(Value, _NoUnit) ->
  Value.


hex2bin(HexStr) when is_binary(HexStr) -> hex2bin(binary_to_list(HexStr));
hex2bin(HexStr) -> hex2bin(HexStr, []).

hex2bin("", Bins) -> list_to_binary(lists:reverse(Bins));
hex2bin(HexStr, Bins) ->
  Bytes = string:slice(HexStr, 0, 2),
  Word = list_to_integer(Bytes, 16),
  hex2bin(string:slice(HexStr, 2), [Word | Bins]).


bytes_to_words(Bytes) -> bytes_to_words(Bytes, []).

bytes_to_words(<<>>, Words) -> lists:reverse(Words);
bytes_to_words(<<Word:16, Rest/binary>>, Words) ->
  bytes_to_words(Rest, [Word | Words]).