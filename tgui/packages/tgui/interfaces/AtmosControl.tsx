import { Box, LabeledList, NoticeBox, Section } from 'tgui-core/components';
import { capitalize } from 'tgui-core/string';
import { useBackend } from '../backend';

export type AtmosData = {
  sensors: Sensor[];
  maxrate: number;
  maxpressure: number;
};

type Sensor = {
  id_tag: string;
  name: string;
  datapoints: Datapoint[];
};

type Datapoint = {
  datapoint: string;
  data: number | string | null;
  unit: string;
  error?: string | null;
};

const getDatapointLabel = (datapoint: string) => {
  if (datapoint === 'moles') {
    return 'Current Moles';
  }
  if (datapoint === 'gas_delta') {
    return 'Round Change';
  }
  return capitalize(datapoint);
};

const formatGasDelta = (delta: number, unit: string) => {
  if (delta > 0) {
    return `+${delta} ${unit} gained`;
  }
  if (delta < 0) {
    return `${Math.abs(delta)} ${unit} lost`;
  }
  return 'No net change';
};

export const AtmosControl = (props) => {
  const { act, data } = useBackend<AtmosData>();
  return data.sensors.length ? (
    <SensorData />
  ) : (
    <NoticeBox>No sensors connected.</NoticeBox>
  );
};

export const SensorData = (props) => {
  const { act, data } = useBackend<AtmosData>();
  return (
    <>
      {data.sensors.map((sensor) => (
        <Section title={sensor.name} key={sensor.id_tag}>
          <LabeledList>
            {sensor.datapoints.map((datapoint) =>
              datapoint.data !== null || datapoint.error ? (
                <LabeledList.Item
                  key={datapoint.datapoint}
                  label={getDatapointLabel(datapoint.datapoint)}
                >
                  {datapoint.error ? (
                    <Box color="bad">{datapoint.error}</Box>
                  ) : datapoint.datapoint === 'gas_delta' &&
                    typeof datapoint.data === 'number' ? (
                    formatGasDelta(datapoint.data, datapoint.unit)
                  ) : (
                    <>
                      {datapoint.data} {datapoint.unit}
                    </>
                  )}
                </LabeledList.Item>
              ) : (
                ''
              ),
            )}
          </LabeledList>
        </Section>
      ))}
    </>
  );
};
