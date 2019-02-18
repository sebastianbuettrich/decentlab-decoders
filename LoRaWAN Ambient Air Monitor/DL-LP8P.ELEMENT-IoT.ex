
# https://www.decentlab.com/support

defmodule Parser do
  use Platform.Parsing.Behaviour
  
  ## Test payloads
  # 020578000f67bd618d1cedbd1081d981f4895b0bd80bb50000959895390c25
  # 020578000b67bd618d1cedbd100c25
  # 02057800080c25
  
  def fields do
    [
      %{field: "Air temperature", display: "Air temperature", unit: "°C"},
      %{field: "Air humidity", display: "Air humidity", unit: "%"},
      %{field: "Barometer temperature", display: "Barometer temperature", unit: "°C"},
      %{field: "Barometric pressure", display: "Barometric pressure", unit: "Pa"},
      %{field: "CO2 concentration", display: "CO2 concentration", unit: "ppm"},
      %{field: "CO2 concentration LPF", display: "CO2 concentration LPF", unit: "ppm"},
      %{field: "CO2 sensor temperature", display: "CO2 sensor temperature", unit: "°C"},
      %{field: "Capacitor voltage 1", display: "Capacitor voltage 1", unit: "V"},
      %{field: "Capacitor voltage 2", display: "Capacitor voltage 2", unit: "V"},
      %{field: "CO2 sensor status", display: "CO2 sensor status", unit: ""},
      %{field: "Raw IR reading", display: "Raw IR reading", unit: ""},
      %{field: "Raw IR reading LPF", display: "Raw IR reading LPF", unit: ""},
      %{field: "Battery voltage", display: "Battery voltage", unit: "V"}
    ]
  end

  def parse(<<2, device_id::size(16), flags::binary-size(2), words::binary>>, _meta) do
    {_remaining, result} =
      {words, %{"Device ID" => device_id, "Protocol version" => 2}}
      |> sensor0(flags)
      |> sensor1(flags)
      |> sensor2(flags)
      |> sensor3(flags)

    result
  end
  
  defp sensor0({<<x0::size(16), x1::size(16), remaining::binary>>, result},
               <<_::size(15), 1::size(1), _::size(0)>>) do
    {remaining,
     Map.merge(result,
               %{
                 "Air temperature" => 175.72 * x0 / 65536 - 46.85,
                 "Air humidity" => 125 * x1 / 65536 - 6
               })}
  end
  defp sensor0(result, _flags), do: result
  
  defp sensor1({<<x0::size(16), x1::size(16), remaining::binary>>, result},
               <<_::size(14), 1::size(1), _::size(1)>>) do
    {remaining,
     Map.merge(result,
               %{
                 "Barometer temperature" => (x0 - 5000) / 100,
                 "Barometric pressure" => x1 * 2
               })}
  end
  defp sensor1(result, _flags), do: result
  
  defp sensor2({<<x0::size(16), x1::size(16), x2::size(16), x3::size(16), x4::size(16), x5::size(16), x6::size(16), x7::size(16), remaining::binary>>, result},
               <<_::size(13), 1::size(1), _::size(2)>>) do
    {remaining,
     Map.merge(result,
               %{
                 "CO2 concentration" => x0 - 32768,
                 "CO2 concentration LPF" => x1 - 32768,
                 "CO2 sensor temperature" => (x2 - 32768) / 100,
                 "Capacitor voltage 1" => x3 / 1000,
                 "Capacitor voltage 2" => x4 / 1000,
                 "CO2 sensor status" => x5,
                 "Raw IR reading" => x6,
                 "Raw IR reading LPF" => x7
               })}
  end
  defp sensor2(result, _flags), do: result
  
  defp sensor3({<<x0::size(16), remaining::binary>>, result},
               <<_::size(12), 1::size(1), _::size(3)>>) do
    {remaining,
     Map.merge(result,
               %{
                 "Battery voltage" => x0 / 1000
               })}
  end
  defp sensor3(result, _flags), do: result
  
end