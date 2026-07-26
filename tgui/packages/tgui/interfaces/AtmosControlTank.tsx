import {
  Button,
  LabeledList,
  NoticeBox,
  NumberInput,
  Section,
  Table,
} from 'tgui-core/components';
import type { BooleanLike } from 'tgui-core/react';
import { useBackend } from '../backend';
import { Window } from '../layouts';
import { AtmosControl } from './AtmosControl';

export type TankData = {
  maxrate: number;
  maxpressure: number;
  input: Input;
  output: Output;
  logs: LogEntry[] | null;
};

type LogEntry = {
  roundID: number;
  roundName: string;
  gas_type: string;
  tank_level: number;
};

type Input = {
  power: BooleanLike;
  rate: number;
  setrate: number;
};

type Output = {
  power: BooleanLike;
  pressure: number;
  setpressure: number;
};

export const AtmosControlTank = (props) => {
  const { act, data } = useBackend<TankData>();
  return (
    <Window>
      <Window.Content scrollable>
        <Section>
          <AtmosControl />
        </Section>
        <Section title="Tank Control System">
          {data.input ? (
            <InputWindow />
          ) : (
            <Button
              content="Search Input Port"
              onClick={() => act('in_refresh_status')}
            />
          )}
          {data.output ? (
            <OutputWindow />
          ) : (
            <Button
              content="Search Output Port"
              onClick={() => act('out_refresh_status')}
            />
          )}
        </Section>
        {data.logs && <GasStorageLogs />}
      </Window.Content>
    </Window>
  );
};

export const GasStorageLogs = (props) => {
  const { data } = useBackend<TankData>();
  return (
    <Section title="Gas Storage Logs — Past Ten Rounds">
      {data.logs?.length ? (
        <Table>
          <Table.Row header>
            <Table.Cell>Record ID</Table.Cell>
            <Table.Cell>Round</Table.Cell>
            <Table.Cell>Gas</Table.Cell>
            <Table.Cell>Tank Level</Table.Cell>
          </Table.Row>
          {data.logs.map((entry) => (
            <Table.Row key={`${entry.gas_type}-${entry.roundID}`}>
              <Table.Cell>{entry.roundID}</Table.Cell>
              <Table.Cell>{entry.roundName}</Table.Cell>
              <Table.Cell>{entry.gas_type}</Table.Cell>
              <Table.Cell>{entry.tank_level} kPa</Table.Cell>
            </Table.Row>
          ))}
        </Table>
      ) : (
        <NoticeBox>No completed-round gas storage records available.</NoticeBox>
      )}
    </Section>
  );
};

export const InputWindow = (props) => {
  const { act, data } = useBackend<TankData>();
  return (
    <LabeledList>
      <LabeledList.Item label="Input">
        <Button
          content={data.input.power ? 'Injecting' : 'On Hold'}
          color={data.input.power ? 'good' : ''}
          icon="power-off"
          onClick={() => act('in_toggle_injector')}
        />
      </LabeledList.Item>
      <LabeledList.Item label="Flowrate Limit">
        <NumberInput
          value={data.input.rate}
          minValue={0}
          maxValue={data.maxrate}
          unit="L/s"
          step={10}
          onChange={(value) =>
            act('in_set_flowrate', { in_set_flowrate: value })
          }
        />
      </LabeledList.Item>
    </LabeledList>
  );
};

export const OutputWindow = (props) => {
  const { act, data } = useBackend<TankData>();
  return (
    <Section>
      <LabeledList>
        <LabeledList.Item label="Output">
          <Button
            content={data.output.power ? 'Open' : 'Closed'}
            color={data.output.power ? 'good' : ''}
            icon="power-off"
            onClick={() => act('out_toggle_power')}
          />
        </LabeledList.Item>
        <LabeledList.Item label="Pressure Limit">
          <NumberInput
            value={data.output.pressure}
            minValue={0}
            maxValue={data.maxpressure}
            unit="kPa"
            step={100}
            onChange={(value) =>
              act('out_set_pressure', { out_set_pressure: value })
            }
          />
        </LabeledList.Item>
      </LabeledList>
    </Section>
  );
};
