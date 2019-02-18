
# https://www.decentlab.com/support

defmodule Parser do
  use Platform.Parsing.Behaviour
  
  ## Test payloads
  # 020bbd007f0b926a515d48bc4e0262006981c7000093d4000b0111
  # 020bbd006f0b926a515d48bc4e02620069000b0111
  # 020bbd00010b92
  
  def fields do
    [
      %{field: "Battery voltage", display: "Battery voltage", unit: "V"},
      %{field: "Air temperature", display: "Air temperature", unit: "°C"},
      %{field: "Air humidity", display: "Air humidity", unit: "%"},
      %{field: "Barometric pressure", display: "Barometric pressure", unit: "Pa"},
      %{field: "Ambient light (visible + infrared)", display: "Ambient light (visible + infrared)", unit: ""},
      %{field: "Ambient light (infrared)", display: "Ambient light (infrared)", unit: ""},
      %{field: "Illuminance", display: "Illuminance", unit: "lx"},
      %{field: "CO2 concentration", display: "CO2 concentration", unit: "ppm"},
      %{field: "CO2 sensor status", display: "CO2 sensor status", unit: ""},
      %{field: "Raw IR reading", display: "Raw IR reading", unit: ""},
      %{field: "Activity counter", display: "Activity counter", unit: ""},
      %{field: "Total VOC", display: "Total VOC", unit: "ppb"}
    ]
  end

  def parse(<<2, device_id::size(16), flags::binary-size(2), words::binary>>, _meta) do
    {_remaining, result} =
      {words, %{"Device ID" => device_id, "Protocol version" => 2}}
      |> sensor0(flags)
      |> sensor1(flags)
      |> sensor2(flags)
      |> sensor3(flags)
      |> sensor4(flags)
      |> sensor5(flags)
      |> sensor6(flags)

    result
  end
  
  defp sensor0({<<x0::size(16), remaining::binary>>, result},
               <<_::size(15), 1::size(1), _::size(0)>>) do
    {remaining,
     Map.merge(result,
               %{
                 "Battery voltage" => x0 / 1000
               })}
  end
  defp sensor0(result, _flags), do: result
  
  defp sensor1({<<x0::size(16), x1::size(16), remaining::binary>>, result},
               <<_::size(14), 1::size(1), _::size(1)>>) do
    {remaining,
     Map.merge(result,
               %{
                 "Air temperature" => 175 * x0 / 65535 - 45,
                 "Air humidity" => 100 * x1 / 65535
               })}
  end
  defp sensor1(result, _flags), do: result
  
  defp sensor2({<<x0::size(16), remaining::binary>>, result},
               <<_::size(13), 1::size(1), _::size(2)>>) do
    {remaining,
     Map.merge(result,
               %{
                 "Barometric pressure" => x0 * 2
               })}
  end
  defp sensor2(result, _flags), do: result
  
  defp sensor3({<<x0::size(16), x1::size(16), remaining::binary>>, result},
               <<_::size(12), 1::size(1), _::size(3)>>) do
    {remaining,
     Map.merge(result,
               %{
                 "Ambient light (visible + infrared)" => x0,
                 "Ambient light (infrared)" => x1,
                 "Illuminance" => max(max(1.0 * x0 - 1.64 * x1, 0.59 * x0 - 0.86 * x1), 0) * 1.5504
               })}
  end
  defp sensor3(result, _flags), do: result
  
  defp sensor4({<<x0::size(16), x1::size(16), x2::size(16), remaining::binary>>, result},
               <<_::size(11), 1::size(1), _::size(4)>>) do
    {remaining,
     Map.merge(result,
               %{
                 "CO2 concentration" => x0 - 32768,
                 "CO2 sensor status" => x1,
                 "Raw IR reading" => x2
               })}
  end
  defp sensor4(result, _flags), do: result
  
  defp sensor5({<<x0::size(16), remaining::binary>>, result},
               <<_::size(10), 1::size(1), _::size(5)>>) do
    {remaining,
     Map.merge(result,
               %{
                 "Activity counter" => x0
               })}
  end
  defp sensor5(result, _flags), do: result
  
  defp sensor6({<<x0::size(16), remaining::binary>>, result},
               <<_::size(9), 1::size(1), _::size(6)>>) do
    {remaining,
     Map.merge(result,
               %{
                 "Total VOC" => x0
               })}
  end
  defp sensor6(result, _flags), do: result
  
end