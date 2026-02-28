import { BooleanLike } from '../../common/react';
import { useBackend } from '../backend';
import {
  Box,
  Button,
  LabeledList,
  NoticeBox,
  Section,
  Table,
  Tabs,
} from '../components';
import { round } from 'common/math';
import { Window } from '../layouts';

type EnvRow = {
  name: string;
  value: number;
  unit: string;
  danger_level: 0 | 1 | 2;
};

type VentInfo = {
  id_tag: string;
  long_name: string;
  power: BooleanLike;
  checks: number; // bitfield
  direction: string; // "siphon" or other
  external: number;
};

type ScrubberFilter = { name: string; command: string; val: BooleanLike };
type ScrubberInfo = {
  id_tag: string;
  long_name: string;
  power: BooleanLike;
  scrubbing: BooleanLike;
  panic: BooleanLike;
  filters: ScrubberFilter[];
};

type ModeInfo = {
  name: string;
  mode: number;
  selected: BooleanLike;
  danger: BooleanLike;
};

type ThresholdSetting = { env: string; val: number; selected: number };
type ThresholdRow = { name: string; settings: ThresholdSetting[] };

type Data = {
  // access / session
  locked: BooleanLike;
  remote_connection: BooleanLike;
  remote_access: BooleanLike;
  can_control: BooleanLike;

  // top bar
  rcon: number; // 1/2/3
  target_temperature: string;

  // status
  has_environment: BooleanLike;
  environment?: EnvRow[];
  total_danger: 0 | 1 | 2;
  atmos_alarm: BooleanLike;

  // navigation
  screen: number; // 1..5

  // per-screen payload
  mode?: number;
  vents?: VentInfo[];
  scrubbers?: ScrubberInfo[];
  modes?: ModeInfo[];
  thresholds?: ThresholdRow[];
};

const f1 = (n?: number) => round(n ?? 0, 0.1);

const dangerColor = (lvl?: number) => {
  switch (Number(lvl)) {
    case 2:
      return 'bad';
    case 1:
      return 'average';
    default:
      return 'good';
  }
};

export const AirAlarm = (_props, context) => {
  const { act, data } = useBackend<Data>(context);

  const {
    locked,
    remote_connection,
    remote_access,
    can_control,

    rcon,
    target_temperature,

    has_environment,
    environment = [],
    total_danger,
    atmos_alarm,

    screen,

    mode,
    vents = [],
    scrubbers = [],
    modes = [],
    thresholds = [],
  } = data;

  const remoteRestricted = remote_connection && !remote_access;
  const lockRestricted = locked && !remote_connection;

  return (
    <Window width={325} height={625}>
      <Window.Content scrollable>
        <Section title="Air Status">
          {has_environment ? (
            <LabeledList>
              {environment.map((row, i) => (
                <LabeledList.Item key={i} label={row.name}>
                  <Box color={dangerColor(row.danger_level)}>
                    {f1(row.value)} {row.unit}
                  </Box>
                </LabeledList.Item>
              ))}
              <LabeledList.Item label="Local Status">
                <Box color={dangerColor(total_danger)}>
                  {Number(total_danger) === 2
                    ? 'DANGER: Internals Required'
                    : Number(total_danger) === 1
                      ? 'Caution'
                      : 'Optimal'}
                </Box>
              </LabeledList.Item>
              <LabeledList.Item label="Area Status">
                {atmos_alarm ? (
                  <Box color="bad">Atmosphere alert in area</Box>
                ) : (
                  <Box>No alerts</Box>
                )}
              </LabeledList.Item>
            </LabeledList>
          ) : (
            <NoticeBox danger>
              Warning: Cannot obtain air sample for analysis.
            </NoticeBox>
          )}
        </Section>

        <Section title="Remote Control / Thermostat">
          <LabeledList>
            <LabeledList.Item label="Remote Control">
              <Button
                selected={rcon === 1}
                disabled={remoteRestricted && rcon !== 1}
                onClick={() => act('set_rcon', { rcon: 1 })}
              >
                Off
              </Button>
              <Button
                selected={rcon === 2}
                disabled={remoteRestricted && rcon !== 2}
                onClick={() => act('set_rcon', { rcon: 2 })}
              >
                Auto
              </Button>
              <Button
                selected={rcon === 3}
                disabled={remoteRestricted && rcon !== 3}
                onClick={() => act('set_rcon', { rcon: 3 })}
              >
                On
              </Button>
            </LabeledList.Item>

            <LabeledList.Item label="Thermostat">
              <Button onClick={() => act('set_temperature')}>
                {target_temperature}
              </Button>
            </LabeledList.Item>
          </LabeledList>
        </Section>

        {(lockRestricted || remoteRestricted) && (
          <NoticeBox>
            {remote_connection
              ? '(Current remote control settings and alarm status restricts access.)'
              : '(Swipe ID card to unlock interface.)'}
          </NoticeBox>
        )}

        {can_control && (
          <>
            <Section>
              <Tabs>
                <Tabs.Tab
                  selected={screen === 1}
                  onClick={() => act('set_screen', { screen: 1 })}
                >
                  Main
                </Tabs.Tab>
                <Tabs.Tab
                  selected={screen === 3}
                  onClick={() => act('set_screen', { screen: 3 })}
                >
                  Scrubbers
                </Tabs.Tab>
                <Tabs.Tab
                  selected={screen === 2}
                  onClick={() => act('set_screen', { screen: 2 })}
                >
                  Vents
                </Tabs.Tab>
                <Tabs.Tab
                  selected={screen === 4}
                  onClick={() => act('set_screen', { screen: 4 })}
                >
                  Modes
                </Tabs.Tab>
                <Tabs.Tab
                  selected={screen === 5}
                  onClick={() => act('set_screen', { screen: 5 })}
                >
                  Sensors
                </Tabs.Tab>
              </Tabs>
            </Section>

            {screen === 1 && (
              <Section title="Main Menu">
                <Button
                  onClick={() =>
                    act(atmos_alarm ? 'atmos_reset' : 'atmos_alarm')
                  }
                >
                  {atmos_alarm
                    ? 'Reset - Area Atmospheric Alarm'
                    : 'Activate - Area Atmospheric Alarm'}
                </Button>

                <Box mt={1} />

                <Button
                  color={Number(mode) === 3 ? 'red' : 'yellow'}
                  onClick={() =>
                    act('set_mode', { mode: Number(mode) === 3 ? 1 : 3 })
                  }
                >
                  {Number(mode) === 3
                    ? 'PANIC SIPHON ACTIVE - Turn siphoning off'
                    : 'ACTIVATE PANIC SIPHON IN AREA'}
                </Button>
              </Section>
            )}

            {screen === 2 && (
              <Section title="Vents Control">
                {vents.length ? (
                  vents.map((v) => (
                    <Section key={v.id_tag} title={v.long_name}>
                      <LabeledList>
                        <LabeledList.Item label="Operating">
                          <Button
                            color={v.power ? undefined : 'red'}
                            onClick={() =>
                              act('device_command', {
                                id_tag: v.id_tag,
                                command: 'power',
                                val: v.power ? 0 : 1,
                              })
                            }
                          >
                            {v.power ? 'On' : 'Off'}
                          </Button>
                        </LabeledList.Item>

                        <LabeledList.Item label="Operation Mode">
                          {v.direction === 'siphon'
                            ? 'Siphoning'
                            : 'Pressurizing'}
                        </LabeledList.Item>

                        <LabeledList.Item label="Pressure Checks">
                          <Button
                            selected={!!(v.checks & 1)}
                            onClick={() =>
                              act('device_command', {
                                id_tag: v.id_tag,
                                command: 'checks',
                                val: v.checks ^ 1,
                              })
                            }
                          >
                            External
                          </Button>
                          <Button
                            selected={!!(v.checks & 2)}
                            onClick={() =>
                              act('device_command', {
                                id_tag: v.id_tag,
                                command: 'checks',
                                val: v.checks ^ 2,
                              })
                            }
                          >
                            Internal
                          </Button>
                        </LabeledList.Item>

                        <LabeledList.Item label="External Pressure Bound">
                          <Button
                            onClick={() =>
                              act('set_external_pressure', { id_tag: v.id_tag })
                            }
                          >
                            {f1(v.external)}
                          </Button>
                          <Button
                            onClick={() =>
                              act('reset_external_pressure', {
                                id_tag: v.id_tag,
                              })
                            }
                          >
                            Reset
                          </Button>
                        </LabeledList.Item>
                      </LabeledList>
                    </Section>
                  ))
                ) : (
                  <NoticeBox>No vents connected.</NoticeBox>
                )}
              </Section>
            )}

            {screen === 3 && (
              <Section title="Scrubbers Control">
                {scrubbers.length ? (
                  scrubbers.map((s) => (
                    <Section key={s.id_tag} title={s.long_name}>
                      <LabeledList>
                        <LabeledList.Item label="Operating">
                          <Button
                            color={s.power ? undefined : 'red'}
                            onClick={() =>
                              act('device_command', {
                                id_tag: s.id_tag,
                                command: 'power',
                                val: s.power ? 0 : 1,
                              })
                            }
                          >
                            {s.power ? 'On' : 'Off'}
                          </Button>
                        </LabeledList.Item>

                        <LabeledList.Item label="Operation Mode">
                          <Button
                            color={s.scrubbing ? undefined : 'red'}
                            onClick={() =>
                              act('device_command', {
                                id_tag: s.id_tag,
                                command: 'scrubbing',
                                val: s.scrubbing ? 0 : 1,
                              })
                            }
                          >
                            {s.scrubbing ? 'Scrubbing' : 'Siphoning'}
                          </Button>
                        </LabeledList.Item>

                        <LabeledList.Item label="Filters">
                          {s.filters?.map((f) => (
                            <Button
                              key={f.command}
                              selected={!!f.val}
                              onClick={() =>
                                act('device_command', {
                                  id_tag: s.id_tag,
                                  command: f.command,
                                  val: f.val ? 0 : 1,
                                })
                              }
                            >
                              {f.name}
                            </Button>
                          ))}
                        </LabeledList.Item>
                      </LabeledList>
                    </Section>
                  ))
                ) : (
                  <NoticeBox>No scrubbers connected.</NoticeBox>
                )}
              </Section>
            )}

            {screen === 4 && (
              <Section title="Environmental Modes">
                {modes.map((m, i) => (
                  <Button
                    key={i}
                    fluid
                    color={
                      m.selected ? (m.danger ? 'red' : undefined) : undefined
                    }
                    selected={m.selected && !m.danger}
                    onClick={() => act('set_mode', { mode: m.mode })}
                  >
                    {m.name}
                  </Button>
                ))}
              </Section>
            )}

            {screen === 5 && (
              <Section title="Alarm Threshold">
                <Box mb={1}>Partial pressure for gases.</Box>
                <Table>
                  <Table.Row header>
                    <Table.Cell />
                    <Table.Cell>
                      <Box color="bad">min2</Box>
                    </Table.Cell>
                    <Table.Cell>
                      <Box color="average">min1</Box>
                    </Table.Cell>
                    <Table.Cell>
                      <Box color="average">max1</Box>
                    </Table.Cell>
                    <Table.Cell>
                      <Box color="bad">max2</Box>
                    </Table.Cell>
                  </Table.Row>

                  {thresholds.map((row, i) => (
                    <Table.Row key={i}>
                      <Table.Cell>{row.name}</Table.Cell>
                      {row.settings.map((s, j) => (
                        <Table.Cell key={j}>
                          <Button
                            onClick={() =>
                              act('set_threshold', { env: s.env, var: s.val })
                            }
                          >
                            {s.selected >= 0 ? f1(s.selected) : 'Off'}
                          </Button>
                        </Table.Cell>
                      ))}
                    </Table.Row>
                  ))}
                </Table>
              </Section>
            )}
          </>
        )}
      </Window.Content>
    </Window>
  );
};

export default AirAlarm;
